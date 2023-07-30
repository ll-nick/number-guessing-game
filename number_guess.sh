#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

WELCOME() {
  echo -e "\n~~~Number Guessing Game~~~\n"

  echo "Enter your username:"
  read USERNAME

  USER_ID=$($PSQL "SELECT user_id FROM users WHERE name='$USERNAME'")

  if [[ -z $USER_ID ]]
  then
    echo "Welcome, $USERNAME! It looks like this is your first time here."
    ADD_USER_RESULT=$($PSQL "INSERT INTO users(name) VALUES ('$USERNAME')")
    USER_ID=$($PSQL "SELECT user_id FROM users WHERE name='$USERNAME'")
  else
    USER_QUERY=$($PSQL "SELECT num_games, least_guesses FROM users WHERE user_id='$USER_ID'")
    IFS="|" read NUM_GAMES LEAST_GUESSES <<< "$USER_QUERY"
    echo "Welcome back, $USERNAME! You have played $NUM_GAMES games, and your best game took $LEAST_GUESSES guesses."
  fi

  NUMBER=$(( $RANDOM % 1000 + 1 ))
  TRIES=0

  GUESS "Guess the secret number between 1 and 1000:"
}

GUESS() {
  if [[ "$1" ]]
  then
    echo -e "\n$1"
  fi

  read GUESS
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    GUESS "That is not an integer, guess again:"
  fi

  if (( GUESS > NUMBER ))
  then
    ((TRIES++))
    GUESS "It's lower than that, guess again:"
  elif (( GUESS < NUMBER ))
  then
    ((TRIES++))
    GUESS "It's higher than that, guess again:"
  else
    ((TRIES++))
    echo "You guessed it in $TRIES tries. The secret number was $NUMBER. Nice job!"
    UPDATE_DATABASE
  fi
}

UPDATE_DATABASE() {
  INC_GAMES_RESULT=$($PSQL "UPDATE users SET num_games = num_games + 1 WHERE user_id = $USER_ID")
  
  CURRENT_BEST=$($PSQL "SELECT least_guesses FROM users WHERE user_id = $USER_ID")
  if [[ -z $CURRENT_BEST || $TRIES -lt $CURRENT_BEST ]]
  then
    SET_HIGHSCORE_RESULT=$($PSQL "UPDATE users SET least_guesses = $TRIES WHERE user_id = $USER_ID")
  fi
}

WELCOME
