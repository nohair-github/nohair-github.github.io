#!/bin/zsh

# Wordle solver by gsb
# 11/20/22

print -n wordle_solver.v0.02.sh

# Version 0.01: getting script to function, including lots of diagnostic
# and debug messages.

# Version 0.02: Less debug and extraneous messages, more informative messaging, corrected
# formatting, correcting and improving logic, correcting regexs, changing variable names to all caps.

# To be done: analysis after each guess displaying remaining words, letter frequency,
# suggested guesses, and so on.

print

# Define array of guessed words
declare -a GUESS

# Create/clear tmp files

if [ -e list.tmp ]
then
  rm list.tmp
fi
touch list.tmp

# Preload list.tmp with Wordle answer list
cat wordle_answers.txt > list.tmp
TOTAL=$(wc -l < list.tmp)
TOTAL=${TOTAL// }

# Main loop through guesses 1-6

for i in {1..6}
do
  
# Input guesses 
  print -n "Enter guesses as 5 letter word lowercase."
  print
  print -n "Enter guess word no. $i:"
  read -r RESP1

# Confirm
  print
  #print -n "Guess is $RESP1"
  OFFSET=$(($i-1))
  GUESS[$i]=($RESP1)
  print
  print -n "GUESS[$i] is ${GUESS[$i]}"
  print

# Step #1: to eliminate words containing unmatched letters

  print -n "Did any letters NOT match at all? (y/n)"
  read -r RESP2
    if [ "$RESP2" = "y" ]; then
      print
      print -n "Enter the unmatched letters in any order (like "acb"):"
      read -r WRONG
      # grep words not containing unmatched letters
      cat list.tmp | grep -v --regexp="[$WRONG]" > list_$i.txt
      # Check for grep errors
        if [[ $? -ne "0" ]]
        then
          print -n "Error in grep - Exiting."
          exit 1
        fi

      # Tabulate and display results
      print "Results after step 1:"
      CNT=$(wc -l < list_$i.txt)
      CNT=${CNT// }
      DISCARD=$(( $TOTAL-$CNT ))
      print "$DISCARD words eliminated; $CNT words remaining."
      print -n "See list of remaining words? (y/n)"
      read -r RESP3
        if [[ "$RESP3" = "y" ]]
        then
          cat list_$i.txt
        fi 

    elif [[ "$RESP2" = "n" ]]
    then
      print -n "All letters guessed. You may be a winner (or close to it)!"
      cat list.tmp > list_$i.txt
    else
      print -n "Error - incorrect input"
      exit 2
    fi
# End of step #1

# Step #2: secondary loop to eliminate words without perfectly matched letter(s) in correct position

  LET=$( echo "${GUESS[$i]}" | tr -d "$WRONG" )
  #print -n "Letters remaining are $LET"
  print 
  print -n "That means the letters $LET matched in some way. Correct? (y/n)"
  read -r RESP4
    if [ "$RESP4" = "y" ]
    then
      print -n "Did any letters match in the correct position (green square)? (y/n)"
      read -r RESP5
        if [ "$RESP5" = "y" ]
	then
          print -n "Enter letter(s) which exactly matched (in any order):"
          read -r CORRECT
	  print "You entered $CORRECT"
        elif [ "$RESP5" = "n" ]
        then
          print "No matches in the correct position"
          CORRECT=""
          print
        else
          print "Error - incorrect input. Exiting"
          exit
        fi
    else
      print "Error - letter calculation failed. Exiting"
      exit 3
    fi

    # Find string length of $CORRECT
    LEN="${#CORRECT}"
    print "Number of letters exactly matched is $LEN"

    # Check if $LEN is 1 or greater and loop only if there are exactly matching letters
    if [[ $LEN -ge 1 ]]
    then

      # Loop through matching letters 
      for j in {1..$LEN}
      do
        OFFSET=$(( $j-1 ))
        #print "\$OFFSET is $OFFSET"
        CHOICE=${CORRECT:$OFFSET:1}
        print
        print "Finding words with $CHOICE in the correct position."

        # Find position of first matched letter in the GUESS[i].
        BEGIN=${GUESS[$i]/$CHOICE*/}
        INDEX=${#BEGIN}
        print "Index of $CHOICE in GUESS[$i] is $INDEX"

        # Set up a template for regex
        TEMPLATE="....."
        PATTERN="${TEMPLATE:0:$INDEX}""$CHOICE""${TEMPLATE:$(( $INDEX+1 ))}"
        print "\$PATTERN is $PATTERN"

        # Now select only those words which match pattern
        cat list_$i.txt | grep --regexp="$PATTERN" > list.tmp

        # Check for grep errors
        if [[ $? -ne "0" ]]
        then
          print -n "Error in grep. Exiting."
          exit 4
        fi

        # Tabulate and display results
        print "After matching for words containing $CHOICE in pattern $PATTERN:"
        CURRENT=$(wc -l < list_$i.txt)
	CNT=$(wc -l < list.tmp)
        CNT=${CNT// }
        DISCARD=$(( $CURRENT-$CNT ))
        print "$DISCARD further words eliminated; $CNT words remaining."
        print -n "See list of remaining words? (y/n)"
        read -r RESP6
          if [[ "$RESP6" = "y" ]]
          then
            cat list.tmp
          fi  
        cat list.tmp > list_$i.txt
      done
      print "Finished checking perfectly matched letters."

    else
    print "No perfectly matched letters."
      print
    fi

# End of step 2

# Step 3: select words which contain matching letters not in the correct position,
# that is, with a yellow square.

  # Determine letters left, which by exclusion are those imperfectly mattched
  LET=$( echo "${GUESS[$i]}" | tr -d "$WRONG" | tr -d "$CORRECT" )
  
  # Check if number of letters in $LET is invalid (<1 or >5)
  if [ ${#LET} -lt 1 ]
  then
    print "No further letters to process."
  elif [ ${#LET} -gt 5 ]
  then
    print "\$LET is invalid (>5 letters)"
    exit 5
  else
  # Process any further letters
  
    print -n "Letters remaining are $LET"
    print   
    print -n "That means the letter(s) $LET matched but not in the correct position. Correct? (y/n)"
    read -r RESP7
      if [ "$RESP7" = "y" ]
        then
          print OK
        else
          print "Error - exiting"
          exit 6
      fi

  # Now, loop through letters to exclude words where letter is in wrong position

  # Find string length of $LET
    LEN="${#LET}"
    print "Number of letters imperfectly matched is $LEN"
      
  # Loop through letters in $LET
    for k in {1..$LEN}
    do
      OFFSET=$(( $k-1 ))
      #print "\$OFFSET is $OFFSET"
      CHOICE=${LET:$OFFSET:1}
      print
      print "Now solving for $CHOICE"

      # First find all the words which contain $CHOICE in any position
      cat list_$i.txt | grep --regexp="[$CHOICE]" > list.tmp

      # Tabulate and display results
      CURRENT=$(wc -l < list_$i.txt)
      CNT=$(wc -l < list.tmp)  
      CNT=${CNT// }
      DISCARD=$(( $CURRENT-$CNT ))
      print "Preliminary enumeration of all remaining words containing $CHOICE:"
      print "$DISCARD further words eliminated; $CNT words remaining."
      print -n "See list of remaining words? (y/n)"
      read -r RESP8
       if [[ "$RESP8" = "y" ]]
        then
          cat list.tmp
       fi
       
      cat list.tmp > list_$i.txt 
      
      # Find position of first imperfectly matched letter in the GUESS[i]
      BEGIN=${GUESS[$i]/$CHOICE*/}
      INDEX=${#BEGIN}
      print "Index of $CHOICE in GUESS[$i] is $INDEX"
      
      # Set up a template for regex
      TEMPLATE="....."
      PATTERN="${TEMPLATE:0:$INDEX}"[^"$CHOICE"]"${TEMPLATE:$(( $INDEX+1 ))}"
      print "\$PATTERN is $PATTERN"
      
      # Now select only those words which match pattern
      cat list_$i.txt | grep --regexp="$PATTERN" > list.tmp
        
      # Check for grep errors
        if [[ $? -ne "0" ]]
        then
          print "Error in grep."
          print "Likely there were no matches to the pattern."
          print "Exiting."
          exit 8
        fi

      # Tabulate and display results
      CURRENT=$(wc -l < list_$i.txt)
      CNT=$(wc -l < list.tmp)
      CNT=${CNT// }
      DISCARD=$(( $CURRENT-$CNT ))
      print "$DISCARD further words eliminated, $CNT words remaining."
      print -n "See list of remaining words? (y/n)"
      read -r RESP9
        if [[ "$RESP9" = "y" ]]
          then
            cat list.tmp
        fi

        cat list.tmp > list_$i.txt

      done

   fi

# End of secondary loop #3


# Now review results after the current guess

  print
  print "Summary of results after guess no. $i:"

  # Tabulate and display results
    CNT=$(wc -l < list_$i.txt)
    CNT=${CNT// }
    DISCARD=$(( $TOTAL-$CNT ))
    print "$TOTAL initial words, $DISCARD words eliminated, $CNT words remaining."
    print

  # If there is only one word remaining
    if [[ $CNT -eq 1 ]]
    then
      print "Wordle is solved. The answer is:"
      cat list_$i.txt
      print
      exit 0

  # If there are only a small number of words, display them
    elif [[ $CNT -le 5 ]]
    then
      print "Just a few words remaining as possible answers:"
      cat list_$i.txt

  # Otherwise, review potential answers    
    else
      print -n "See list of remaining words? (y/n)"
      read -r RESP10
       if [[ "$RESP10" = "y" ]]
         then
           cat list_$i.txt
       fi

     fi

    print -n "Continue with next guess? (y/n)"
    read -r RESP11
    if [[ "$RESP11" = "y" ]]
    then
      print "OK"
    else
      exit 0
    fi

done

# End of primary loop

print
print "Guesses so far are:"
print -l $GUESS
print

print "Finished"

exit 0
