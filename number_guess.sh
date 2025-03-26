#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guessing_game --tuples-only -c"

USERNAME=""

CHECK_STATS(){
  ESCAPED_USERNAME=$(echo "$USERNAME" | sed "s/'/''/g")
  GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE name='$ESCAPED_USERNAME'")
  BEST_GAME=$($PSQL "SELECT MIN(number_of_guesses) FROM games WHERE username='$ESCAPED_USERNAME'")
  if [[ -z $GAMES_PLAYED && -z $BEST_GAME ]]
  then
    START_GAME
  else
    echo -e "Welcome back, $ESCAPED_USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
    START_GAME
  fi
}

MAIN_MENU(){
  echo -e "\nEnter your username:"
  read USERNAME
  if [[ ${#USERNAME} -gt 22 ]]
  then
    echo "Username must be 22 characters or less."
    MAIN_MENU
    return
  fi

  HAVE_USERNAME=$($PSQL "SELECT name FROM users WHERE name='$USERNAME'")
  if [[ -z $HAVE_USERNAME ]]
  then
    echo -e "Welcome, $USERNAME! It looks like this is your first time here."
    INSERTED=$($PSQL "INSERT INTO users (name, games_played) VALUES ('$USERNAME', 0)")
    START_GAME
  else
    CHECK_STATS
  fi
}

START_GAME(){
  SECRET_NUMBER=$((RANDOM % 1000 + 1))
  GUESS_COUNT=0
  echo -e "Guess the secret number between 1 and 1000:"
  while true
  do
    read GUESS
    if [[ ! $GUESS =~ ^[0-9]+$ ]]
    then
      echo "That is not an integer, guess again:"
      continue
    fi
    GUESS_COUNT=$((GUESS_COUNT + 1))
    if [[ $GUESS -eq $SECRET_NUMBER ]]
    then
      echo -e "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"
      INSERT_GAME=$($PSQL "INSERT INTO games (username, secret_number, number_of_guesses) VALUES ('$USERNAME', $SECRET_NUMBER, $GUESS_COUNT)")
      UPDATE_GAMES_PLAYED=$($PSQL "UPDATE users SET games_played = games_played + 1 WHERE name='$USERNAME'")
      break
    elif [[ $GUESS -gt $SECRET_NUMBER ]]
    then
      echo -e "It's lower than that, guess again:"
    else
      echo -e "It's higher than that, guess again:"
    fi
  done
}

MAIN_MENU
