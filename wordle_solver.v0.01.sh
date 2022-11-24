#!/bin/zsh

# Wordle solver by gsb
# 11/20/22

print -n Wordle solver script v 0.01
print

# Define array of guessed words
declare -a guess
declare -a answer

# Create/clear tmp files

if [ -e list.tmp ]
then
  rm list.tmp
fi
touch list.tmp

# Preload list.tmp with Wordle answer list
cat wordle_answers.txt > list.tmp

# Main loop through guesses 1-6

for i in {1..6}
do
  
# Input guesses 
  print -n Enter data for guess no. $i:
  print
  print -n "Enter guess word no. $i:"
  read -r RESP1

# Confirm
  print
  print -n First guess is $RESP1
  offset=$(($i-1))
  guess[$i]=($RESP1)
  print
  print -n "guess[$i] is ${guess[$i]}"
  print

# Step #1: to eliminate words containing unmatched letters

  print -n "Did any letters not match at all? (y/n)"
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
          print -n "Error in grep. Exiting line 53."
          exit 1
        fi

      # Tabulate and display results
      print "Results after step 1:"
      total=$(wc -l < list.tmp)
      cnt=$(wc -l < list_$i.txt)
      discard=$(( $total-$cnt ))
      print "$discard words eliminated; $cnt words remaining."
      print -n "See list of remaining words? (y/n)"
      read -r RESP3
        if [[ "$RESP3" = "y" ]]
        then
          cat list_$i.txt
        fi 

    elif [[ "$RESP2" = "n" ]]
    then
      print -n "All letters guessed. You may be a winner ( or close to it)!"
    else
      print -n "Error - incorrect input"
      exit 1
    fi
# End of step  #1

# Step #2: secondary loop to eliminate words without perfectly matched letter(s) in correct position

  let=$( echo "${guess[$i]}" | tr -d "$WRONG" )
  print -n "Letters remaining are $let"
  print 
  print -n "That means the letters $let matched in some way. Correct? (y/n)"
  read -r RESP2
    if [ "$RESP2" = "y" ]
    then
      print -n "Did any letters match in the correct position (green square)? (y/n)"
      read -r RESP3
        if [ "$RESP3" = "y" ]
	then
          print -n "Enter letter(s) which exactly matched (in any order):"
          read -r CORRECT
	  print "You entered $CORRECT"
        elif [ "$RESP3" = "n" ]
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
      exit 4
    fi

    # Find string length of $CORRECT
    len="${#CORRECT}"
    print "Number of letters exactly matched is $len"

    # Check if $len is 1 or greater and loop only if there are exactly matching letters
    if [[ $len -ge 1 ]]
    then

      # Loop through matching letters 
      for ii in {1..$len}
      do
        offset=$(( $ii-1 ))
        print "\$offset is $offset"
        choice=${CORRECT:$offset:1}
        print "\$choice is $choice"

        # Find position of first matched letter in the guess[i]
        BEGIN=${guess[$i]/$choice*/}
        index=${#BEGIN}
        print "Index of $choice in guess[$i] is $index"

        # Set up a template for regex
        template="....."
        pattern="${template:0:$index}""$choice""${template:$(( $index+1 ))}"
        print "\$pattern is $pattern"

        # Now select only those words which match pattern
        cat list_$i.txt | grep --regexp="$pattern" > list.tmp

        # Check for grep errors
        if [[ $? -ne "0" ]]
        then
          print -n "Error in grep. Exiting."
          exit 1
        fi

        # Tabulate and display results
        print "After matching for words containing $choice in pattern $pattern:"
        current=$(wc -l < list_$i.txt)
	cnt=$(wc -l < list.tmp)
        discard=$(( $current-$cnt ))
        print "$discard further words eliminated; $cnt words remaining."
        print -n "See list of remaining words? (y/n)"
        read -r RESP3
          if [[ "$RESP3" = "y" ]]
          then
            cat list.tmp
          fi  
        cat list.tmp > list_$i.txt
      done

    else
      print "No perfectly matched letters."
      print
    fi

# End of step 2

# Step 3: select words which contain matching letters not in the correct position,
# that is, with a yellow square.

  # Determine letters left, which by exclusion are those imperfectly mattched
  let=$( echo "${guess[$i]}" | tr -d "$WRONG" | tr -d "$CORRECT" )
  
  # Process any further letters
  if [ ${#let} -ge 1 ]
    then
      print -n "Letters remaining are $let"
      print   
      print -n "That means the letter(s) $let matched but not in the correct position. Correct? (y/n)"
      read -r RESP2
      if [ "$RESP2" = "y" ]
        then
          print OK
        else
          print "Error - exiting"
          exit
        fi

  # Find all remaining words in list which contain the imperfectly matched letters.
      cat list_$i.txt | grep --regexp="[$let]" > list.tmp

  # Check for grep errors
      if [[ $? -ne "0" ]]
        then
          print -n "Error in grep. Exiting."
          exit 1
      fi

  # Tabulate and display results
      current=$(wc -l < list_$i.txt)
      cnt=$(wc -l < list.tmp)
      discard=$(( $current-$cnt ))
      print "Preliminary exclusion of words not containing $let:"
      print "$discard further words eliminated; $cnt words remaining."
      print -n "See list of remaining words? (y/n)"
      read -r RESP3
      if [[ "$RESP3" = "y" ]]
        then
          cat list.tmp
      fi

      cat list.tmp > list_$i.txt

  # Now, loop through letters to exclude words where letter is in wrong position

  # Find string length of $let
      len="${#let}"
      print "Number of letters imperfectly matched is $len"
      
  # Loop through letters in $let
      for iii in {1..$len}
      do
        offset=$(( $iii-1 ))
        print "\$offset is $offset"
        choice=${let:$offset:1}
        print "\$choice is $choice"
        
      # Find position of first imperfectly matched letter in the guess[i]
        BEGIN=${guess[$i]/$choice*/}
        index=${#BEGIN}
        print "Index of $choice in guess[$i] is $index"
      
      # Set up a template for regex
        template="....."
        pattern="${template:0:$index}"[^"$choice"]"${template:$(( $index+1 ))}"
        print "\$pattern is $pattern"
      # Now select only those words which match pattern
        cat list_$i.txt | grep --regexp="$pattern" > list.tmp
        
      # Check for grep errors
        if [[ $? -ne "0" ]]
        then
          print -n "Error in grep. Exiting."
          exit 1
        fi

      # Tabulate and display results
        current=$(wc -l < list_$i.txt)
	cnt=$(wc -l < list.tmp)
        discard=$(( $current-$cnt ))
        print "$discard further words eliminated, $cnt words remaining."
        print -n "See list of remaining words? (y/n)"
        read -r RESP3
        if [[ "$RESP3" = "y" ]]
          then
            cat list.tmp
        fi

        cat list.tmp > list_$i.txt

      done
    else
      print "No matches to process"
    fi

# End of secondary loop #3

# Now review results after the current guess

  print
  print "Summary of results after guess no. $i:"
  print

  # Tabulate and display results
    cnt=$(wc -l < list_$i.txt)
    discard=$(( $total-$cnt ))
    print "$total initial words, $discard words eliminated, $cnt words remaining."
    print -n "See list of remaining words? (y/n)"
    read -r RESP3
      if [[ "$RESP3" = "y" ]]
      then
        cat list_$i.txt
      fi

    print -n "Continue with next guess? (y/n)"
    read -r RESP4
    if [[ "$RESP4" = "y" ]]
    then
      print "OK"
    else
      exit
    fi

done

# End of primary loop

print
print "Guesses so far are:"
print -l $guess
print

print "Finished"

exit
