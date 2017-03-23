#!/bin/bash

### meditation.sh 0.5 ~ timer para meditação
### bcardoso @ 2010-2017

### EXEMPLOS DE USO
# ./meditation.sh           [padrão 20 minutos]
# ./meditation.sh 15        [intervalo de 15 minutos]
# ./meditation.sh 15 20 10  [um intervalo de 15, outro de 20 e um de 10]
# ./meditation.sh -r 30     [repete intervalos de 5m/30m indefinidamente]
# ./meditation.sh -set      [rotina de tempos pré-definida]

### CHANGELOG
# 2016-11-27 v0.5: revisão estrutural do código; suprimidas variações da opção '-set'(atualmente apenas um set padrão definido em $SET_TIMES)
# 2016-10-01 v0.4: opção '-r $2' cria loop de '$2'm com intervalos de 5m
# 2016-06-29 v0.3: opção '-set' com uma série de intervalos de 4 horas.
# 2015-02-23 v0.2: opção de usar vários tempos como argumentos.
# 2010-07-24 v0.1: primeira versão


#============================================================================#

### DEFINIÇÕES

# diretorio com arquivos de som
BASEDIR=~/bin/meditation/

# som que será tocado ao fim de cada intervalo
# bigbowl.mp3: http://www.freesound.org/samplesViewSingle.php?id=132
# singing-bell: https://www.freesound.org/people/ryancacophony/sounds/202017/
#SOM=$BASEDIR/bigbowl.mp3
#SOM=$BASEDIR/singing-bell-hit2.mp3
SOM=$BASEDIR/sound/singing-bell-hit2-normalizado.mp3

# player que tocará o som: mplayer // alternative: "/usr/bin/cvlc --play-and-exit"
PLAYER="mplayer -really-quiet -volume 90"

# intervalo padrão em minutos
DEFAULT=20

# rotina pré-definida para opção -set
SET_TIMES="5 25 5 55 5" # ~1h30 focus work (20% of 8h/work-day)
#SET_TIMES="1 1 2 3 5 8 13 21 34" # fibonacci times


#============================================================================#

### FUNÇÕES

# confere a validade do argumento (ie, se é um numero inteiro > 0)
check_time () {
	if [ $1 -gt 0 2> /dev/null ] ; then
		TEMPO=$1
	else # argumento é igual a zero ou não é um número
		echo "Erro: \"$1\" é um argumento inválido."
		echo "Intervalo definido para $DEFAULT minutos."
		TEMPO=$DEFAULT
	fi
}

# conta o tempo dos intervalos e toca o sino
timer () {
	for num in $@ ; do
		# confere se o $num é valido
		check_time $num

		# faz a contagem do tempo
		echo -e "\n[$(date +%H:%M)] Tempo: $TEMPO minutos..."
		sleep "$TEMPO"m
	
		# toca o sino ao final
		$PLAYER $SOM 2> /dev/null
	done
}


#============================================================================#

### MAIN

case $1 in
	
	-h) # AJUDA, mostra principais opções
		head -12 $0
		grep ") \#" $0 | tr "\#" "\t"
		;;

	
	-r) # REPETE um intervalo '$2' a cada 5m, indefinidamente. ex: -r 25
		check_time $2
		echo -e "\nSET DE PRÁTICA: 5m/${TEMPO}m (oo)"
		while ((1)) ; do
			echo -ne "\n>> INTERVALO"
			timer 5
			echo -ne "\n>> PRÁTICA"
			timer $2
		done
		;;


	-set) # SET pré-definido de intervalos ($SET_TIMES)
		echo -e "\nSET DE PRÁTICA: $SET_TIMES"
		timer $SET_TIMES
		;;


	*) # INTERVALO modo padrão ($DEFAULT) ou N argumentos
		if [ -z $1 ] ; then
			timer $DEFAULT
		else
			timer $@
		fi
		;;
	
esac
