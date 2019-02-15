#!/bin/bash
### meditation.sh v0.7 ~ timer para meditação
### bcardoso @ 2010-2019

### EXEMPLOS DE USO
# ./meditation.sh           [padrão 20 minutos]
# ./meditation.sh 15        [intervalo de 15 minutos]
# ./meditation.sh 15 20 10  [um intervalo de 15, outro de 20 e um de 10]
# ./meditation.sh -r 23     [repete continuamente ciclos de 23m por 5m]
# ./meditation.sh -r 30/10  [idem, 30m por 10m]
# ./meditation.sh -set      [rotina de tempos pré-definida]

### CHANGELOG
# 2019-02-15 v0.7: valores no formato x/y como padrão (usar -r é opcional);
# 2017-09-01 v0.6: opção -r aceita valores no formato x/y;
# 2016-11-27 v0.5: revisão estrutural do código; suprimidas variações da opção '-set'(atualmente apenas um set padrão definido em $SET_TIMES);
# 2016-10-01 v0.4: opção '-r $2' cria loop de '$2'm com intervalos de 5m;
# 2016-06-29 v0.3: opção '-set' com uma série de intervalos de 4 horas;
# 2015-02-23 v0.2: opção de usar vários tempos como argumentos;
# 2010-07-24 v0.1: primeira versão.

#============================================================================#

### DEFINIÇÕES

# diretorio com arquivos de som
BASEDIR="${HOME}/bin/meditation"

# som que será tocado ao fim de cada intervalo
# bigbowl.mp3: http://www.freesound.org/samplesViewSingle.php?id=132
# singing-bell: https://www.freesound.org/people/ryancacophony/sounds/202017/
#SOM="$BASEDIR/sound/bigbowl.mp3"
#SOM="$BASEDIR/sound/singing-bell-hit2.mp3"
SOM="$BASEDIR/sound/singing-bell-hit2-normalizado.mp3"

# player para o som
# alternatives: "/usr/bin/cvlc --play-and-exit", "mpv --really-quiet"
PLAYER="mplayer -really-quiet -volume 90"

# intervalo padrão em minutos
DEFAULT_TIME=23
DEFAULT_PAUSE=5

# rotina pré-definida para opção -set
SET_TIMES="23 5 23 5 23" # 79m focus work (~20% of 8h/work-day)

#============================================================================#

### FUNÇÕES

# confere a validade do argumento (ie, se é um numero inteiro > 0)
CHECK_TIME () {
    if [ $1 -gt 0 2> /dev/null ] ; then
	TEMPO=$1
    else
	# argumento é igual a zero ou não é um número
	echo -e "Erro: \"$1\" é inválido. Definindo para $DEFAULT_TIME min.\n"
	TEMPO=$DEFAULT_TIME
    fi
}

# conta o tempo dos intervalos e toca o sino
TIMER () {
    for NUM in $@ ; do
	# confere se o $num é valido
	CHECK_TIME $NUM

	# faz a contagem do tempo
	echo -e "[$(date +%H:%M)] $TEMPO min..."
	sleep "$TEMPO"m
	
	# toca o sino ao final
	($PLAYER $SOM & 2> /dev/null)
    done
}


#============================================================================#

### MAIN
case $1 in
	
    -h) # AJUDA, mostra principais opções
	head -12 $0
	echo -e "\$SET_TIMES = $SET_TIMES\n\$DEFAULT_TIME = $DEFAULT_TIME\n"
	grep ") \#" $0 | sed -e 's/\t/\ /g;s/)\ \#/\t/g'
	echo
	;;

	
    -r) # REPETE um ciclo X/Y. ex: -r 23/5 [ou] -r 50
	shift
		
	# interpreta valores no formato x/y
	if [[ $1 == *"/"* ]]; then
	    X=$(echo $1 | cut -d"/" -f1)
	    Y=$(echo $1 | cut -d"/" -f2)

	# ou somente o valor principal
	else
	    X=$DEFAULT_TIME
	    [ ! -z $1 ] && X=$1
	    Y=$DEFAULT_PAUSE
	fi

	# inicia a repetição contínua do set
	echo -e "\nSET: ${X}m/${Y}m [oo] (^C para sair)\n"
	while :; do
	    TIMER $X $Y
	done
	;;


    -s) # SET de intervalos pré-definido em $SET_TIMES
	echo -e "\nSET: $SET_TIMES\n"
	TIMER $SET_TIMES
	;;


    *) # INTERVALO padrão ($DEFAULT) [ou] ciclo X/Y [ou] N argumentos
	if [ -z $1 ] ; then
	    TIMER $DEFAULT
	    
	elif [[ $1 == *"/"* ]]; then
	    $0 -r $1
	    
	else
	    TIMER $@
	    
	fi
	;;
    
esac
