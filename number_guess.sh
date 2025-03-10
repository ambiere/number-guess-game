#!/bin/bash

PSQL="psql -t --no-align --username=freecodecamp --dbname=number_guess"

ARGUMENTS_ERROR() {
	echo "Invalid arguments. Expected $1 argument, got $2 argument(s)."
	exit
}

GET_USER() {
	if [[ $# -ne 1 ]]; then
		ARGUMENTS_ERROR 1 $#
	fi

	echo $($PSQL -c "SELECT * FROM users WHERE LOWER(username)=LOWER('$1');")
}

DISPLAY_GAME() {
	if [[ $# -ne 1 ]]; then
		ARGUMENTS_ERROR 1 $#
	fi

	USER=$(GET_USER $1)

	if [[ -z $USER ]]; then
		USER_ID=$($PSQL -c "WITH new_row AS (INSERT INTO users(username) VALUES('$REPLY') RETURNING user_id) SELECT user_id FROM new_row;")
		echo "Welcome, $USERNAME! It looks like this is your first time here."
	else
		USER_ID=$(echo "$USER" | cut -d '|' -f 1)
		USERNAME=$(echo "$USER" | cut -d '|' -f 2)
		GAMES_PLAYED=$($PSQL -c "SELECT count(*) FROM games WHERE user_id=$USER_ID;")
		BEST_GAMES=$($PSQL -c "SELECT min(number_of_guess) FROM games WHERE user_id=$USER_ID AND won=true;")

		echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took ${BEST_GAMES:-0} guesses."
	fi
}

EXIT_GAME() {
	echo "Exiting number guess game..."
	if [[ -n $USER_ID ]]; then
		GAME_INSERT_RESULT=$($PSQL -c "INSERT INTO games(user_id, number_of_guess, won) VALUES($USER_ID, $GUESS_COUT, false);")
		exit 1
	fi
	exit 1
}

trap EXIT_GAME SIGINT
echo "Enter your username:"
read -n 22 -e USERNAME
DISPLAY_GAME $USERNAME

START_GAME() {
	GUESS_COUT=0
	RANDOM_NUMBER=$(shuf -i 1-1000 -n 1)
	echo "Guess the secret number between 1 and 1000:"
	read -e GUESS_NUMBER

	while true; do
		GUESS_COUT=$((GUESS_COUT + 1))

		if [[ ! $GUESS_NUMBER =~ [[:digit:]] ]]; then
			echo "That is not an integer, guess again:"
			read -e GUESS_NUMBER
		fi

		case $((${GUESS_NUMBER:-0} > $RANDOM_NUMBER)) in
		1)
			echo "It's lower than that, guess again:"
			read -e GUESS_NUMBER
			;;
		0)
			if [[ ${GUESS_NUMBER:-0} -lt $RANDOM_NUMBER ]]; then
				echo "It's higher than that, guess again:"
				read -e GUESS_NUMBER
			else
				echo "You guessed it in $GUESS_COUT tries. The secret number was $RANDOM_NUMBER. Nice job!"
				GAME_INSERT_RESULT=$($PSQL -c "INSERT INTO games(user_id, number_of_guess, won) VALUES($USER_ID, $GUESS_COUT, true);")
				break
			fi
			;;
		esac
	done
}

START_GAME
