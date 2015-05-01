#!/bin/bash

CX=0 CY=0

declare -a XY

# Необходимые нам клавиатурные коды
KUP=1b5b41
KDOWN=1b5b42
KLEFT=1b5b44
KRIGHT=1b5b43
KSPACE=20
Subj = 'o'

# Убирам курсор
echo -e "\033[?25l"

# Выключаем остальную клавиатуру
ORIG=`stty -g`
stty -echo

function React {
    case $1 in
        $KLEFT)
              if [ $CX -gt 0 ]; then
                  CX=$(($CX-1))
                  PrintField
              fi
           ;;

        $KRIGHT)
              if [ $CX -lt 9 ]; then
                  CX=$(($CX+1))
                  PrintField
              fi
            ;;

        $KUP)
              if [ $CY -gt 0 ]; then
                  CY=$(($CY-1))
                  PrintField
              fi
           ;;

        $KDOWN)
              if [ $CY -lt 9 ]; then
                  CY=$(($CY+1))
                  PrintField
              fi
    esac
}

function PressEvents {
    local real code seq

    # Цикл обработки клавиш, здесь считываются коды клавиш,
    # по паузам между нажатиями собираются комбинации и известные
    # обрабатываются сразу
    while true; do
        # измеряем время выполнения команды read и смотрим код нажатой клавиши
        # awk NR==1||NR==4 забирает только строку №1 (там время real) и №4 (код клавиши)
        eval $( (time -p read -r -s -n1 ch; printf 'code %d\n' "'$ch") 2>&1 |
        awk 'NR==1||NR==4 {print $1 "=" $2}' | tr '\r\n' '  ')

        # read возвращает пусто для Enter и пробела, присваиваем им код 20,
        # а так же возвращаются отрицательные коды для UTF8
        if [ "$code" = 0 ]; then
            code=20
        else
             [ $code -lt 0 ] && code=$((256+$code))

             code=$(printf '%02x' $code)
        fi

        if [ $code = $KSPACE ]; then
            SpaceEvent && return
            continue
        fi

        # Если клавиши идут подряд (задержки по времени нет)
        if [ $real = 0.00 ]; then
            seq="$seq$code"

        # Клавиши идут с задержкой (пользователь не может печатать с нулевой задержкой),
        # значит последовательность собрана, надо начинать новую
        else
            [ "$seq" ] && React $seq
            seq=$code
        fi
    done
}

function SpaceEvent {
    local xy

    # Проверяем, есть ли предмет под курсором
    let xy="$CX+$CY*10"

    # Фигура есть
    if [ "${XY[$xy]}" = "o" ]; then
        XY[$xy]="\s"
    # Фигуры нет
    else
    	XY[$xy]="o"
    fi
}

function ClearKbBuffer {
	while true; do
		delta=`(time -p read -rs -n1 -t1) 2>&1 | awk 'NR==1{print $2}'`
		[[ "$delta" == "0.00" ]] || break
	done
}

function PrintField {
	local x y
	for y in {1..8}; do
    	for x in {1..8}; do
    		echo -en "${XY[$x+y*10]}"
        done
    done
}


#основная часть программы
ClearKbBuffer
PrintField
PressEvents