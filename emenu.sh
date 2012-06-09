#!/bin/bash

# Portage Interface v0.4.3
# euphor][a, euphoria@dopesmoker.net

# Emerge Menu:
# ===========
# 1   Sync portage 
# 
# 2   View system updates
# 3   Update system 
# 
# 4   View world updates
# 5   Update world
# 
# 6   View deep updates
# 7   Update deep
# 
# 8   View /etc updates
# 
# a  Adv. tools
# q  Quit
#
# Adv. Tools:
# ==========
#
# 1   Mirrorselect
#    
# 2   Clean world
# 
# 3   Edit world mask
# 4   Regenerate World Mask
#
# e Emerge menu 
# q Quit

check_root ()
{
ROOT_UID=0

if [ "$UID" -eq "$ROOT_UID" ]
then
  menu
else
  echo "root access required."
fi

exit 0
}

menu ()
{
printf "\n   \033[1;37mEmerge Menu:\033[0m"
printf "\n   \033[1;37m===========\033[0m\n\n"
printf "   1.   Update portage\n\n"			# emerge rsync
printf "   2.   View system updates\n"			# emerge --upgrade --pretend system
printf "   3.   Update system\n\n"			# emerge --upgrade system
printf "   4.   View world updates\n"			# emerge --upgradeonly --pretend world
printf "   5.   Update world\n\n"			# emerge --upgradeonly world
printf "   6.   View deep updates\n"			# emerge --upgradeonly --deep --pretend world
printf "   7.   Update deep\n\n"			# emerge --upgradeonly --deep world
printf "   8.   Update /etc\n\n"			# etc-update
printf "   a.   Adv. Tools\n" 
printf "   q.   Quit\n"
printf "\n"

getresponse
}

advmenu ()
{
printf "\n   \033[1;37mAdv. Tools:\033[0m"
printf "\n   \033[1;37m==========\033[0m\n\n"
printf "   1.   Mirrorselect\n\n"                     	# emerge mirrorselect; mirrorselect
printf "   2.   Clean world\n\n"            	      	# emerge clean
printf "   3.   Edit world mask\n"			# nano -w /var/cache/edb/world
printf "   4.   Regenerate world mask\n\n"		# regenworld
printf "   e.   Emerge Menu\n"
printf "   q.   Quit\n"
printf "\n"

advgetresponse
}

update ()
{
cp /tmp/emerge.log /tmp/emerge.log.bak
echo -e "\nCalculating world dependencies\c"

if [ "$RESUMING" = "1" ]; then
  echo -en " (resuming)...\n"
  $EMERGECOMMAND --resume $MASK 2>&1 | tee /tmp/emerge.log
else 
  echo -e "...\n"
  $EMERGECOMMAND $MASK 2>&1 | tee /tmp/emerge.log
fi

catlog
}

skip ()
{
while echo -en "Skip package and continue updates? (y/n):\n:"
read skipresponse
do
case "$skipresponse" in
  y)
  SKIPPING=1
  echo -e "\nSkipping package...\n\nCalculating world dependencies (resuming)...\n\n"
  $EMERGECOMMAND --resume --skipfirst $MASK 2>&1 | tee /tmp/emerge.log
  notes
  break
  ;;
  n)
  echo ""
  break
  ;;
esac
done

getresponse
}

catlog ()
{
if [ `cat /tmp/emerge.log | grep -c 'Regenerating /etc/ld.so.cache'` = 0 ]; then
  if [ `cat /tmp/emerge.log | grep -c \!\!\!` = "0" ]; then
    echo -n 
  else
    notes
  fi
else
  notes
fi

SKIPPING=2
continue
getresponse
}

notes ()
{
printf "\n\033[1;37m==================================================\033[0m\n\n"
cat /tmp/emerge.log | grep 'GNU info directory'
cat /tmp/emerge.log | grep 'config files in'
cat /tmp/emerge.log | grep 'Type emerge --help'
echo ""

# >>> contains first line of *'s notes
if [ `cat /tmp/emerge.log | grep \\\[ | grep -v Applying | grep -v make | grep -c \*` = "0" ]; then
  echo -e " \033[1;32m*\033[0m No Notes\n"
else
  echo -e " \033[1;32m*\033[0m Notes:\n"
  cat /tmp/emerge.log | grep \\[ | grep -v Applying | grep -v make | grep 'm\*' | grep -v 'GNU info directory' | grep -v 'config files in /etc' | grep -v 'Type emerge --help' | grep -v 'Caching service dependencies...' | less
  echo ""
fi

errors
}

errors ()
{
if [ `cat /tmp/emerge.log | grep -c \!\!\!` = "0" ]; then
  echo -e " \033[1;32m*\033[0m No Errors:\n"
else
  echo -e " \033[1;32m*\033[0m Errors:\n"
  echo -en `cat /tmp/emerge.log | grep \>\>\> | grep emerge | tail -n 1`
  echo " failed."
  cat /tmp/emerge.log | grep \!\!\! | grep -v failed | grep -v WARNING | grep -v 'GNU info directory' | grep -v 'config files in /etc' | grep -v 'Type emerge --help'
  echo ""
#  if [ `cat /tmp/emerge.log | grep -c "emerge (1 of 1)"` = "0" ]; then
  if [ "`cat /tmp/emerge.log | grep emerge | grep -v source | tail -n 1 | awk '{ print $3 }' | awk -F '(' '{ print $2 }'`" = "`cat /tmp/emerge.log | grep emerge | grep -v source | tail -n 1 | awk '{ print $5 }' | awk -F ')' '{ print $1 }'`" ]; then
    echo -n
  else
    if [ `cat /tmp/emerge.log | grep \!\!\! | grep -c 'corrupt or incomplete'` = "1" ]; then
      while echo -en "rm: remove regular file `cat /tmp/emerge.log | grep \!\!\! | grep 'File does not exist' | awk -F ':' '{ print $2 }'`?\n:"
      read rmfile
      do
      case "$rmfile" in
        y)
        rm -v `cat /tmp/emerge.log | grep \!\!\! | grep 'File does not exist' | awk -F ':' '{ print $2 }'`
        update
        break
        ;;
        n)
        echo ""
        break
        ;;       
      esac
      done
    fi
    if [ "$SKIPPING" = "0" ]; then
      echo -n ""
    elif [ "$SKIPPING" = "1" ]; then
      echo -e "Package failed (may skip only once)...\n"
      break
    else
      echo -e "Package failed...\n"
      skip
      break
    fi
  fi
fi

SKIPPING=2
continue
getresponse
}

getresponse ()
{
while echo -en "Please enter command (m for menu):\n:"
read response
do
case "$response" in
  1)
  printf "\n\033[1;37mSyncing portage...\033[0m\n"
  emerge sync
  printf "\b\n"
  continue
  getresponse
  ;;
  2)
  printf "\n\033[1;37mSystem updates:\033[0m\n"
  emerge -up system | less
  printf "\n"
  continue
  getresponse
  ;;
  3)
  if [ "$RESUME" = "3" ]; then
    MASK=system
    RESUMING=1
    EMERGECOMMAND="emerge -u --nospinner --resume"
    update
    break
  else
    MASK=system
    RESUME=3
    RESUMING=0
    EMERGECOMMAND="emerge -u --nospinner"
    update
    break
  fi
  notes
  break
  ;;
  4)
  printf "\n\033[1;37mWorld updates:\033[0m\n"
  emerge -uUp world | less
  printf "\n"
  continue
  getresponse
  ;;
  5)
  if [ "$RESUME" = "5" ]; then 
    MASK=world
    RESUMING=1
    EMERGECOMMAND="emerge -uU --nospinner --resume"
    update
    break
  else 
    MASK=world
    RESUME=5
    RESUMING=0
    EMERGECOMMAND="emerge -uU --nospinner"
    update
    break
  fi
  notes
  break
  ;;
  6)
  printf "\n\033[1;37mDeep updates:\033[0m\n"
  emerge -uDp world | less
  printf "\n"
  continue
  getresponse
  ;;
  7)
  if [ "$RESUME" = "7" ]; then 
    MASK=world
    RESUMING=1
    EMERGECOMMAND="emerge -uD --nospinner --resume"
    update
    break
  else 
    MASK=world
    RESUME=7
    RESUMING=0
    EMERGECOMMAND="emerge -uD --nospinner"
    update
    break
  fi 
  notes
  break
  ;;
  8)
  printf "\n\033[1;37mScanning Configuration files...\033[0m\n"
  etc-update | grep -v "Scanning Configuration files..."
  printf "\n"
  continue
  getresponse
  ;;
  a)
  advmenu
  break
  ;;
  c)
  SKIPPING=0
  catlog
  break
  ;;
  m)
  menu
  break
  ;;
  q)
  break
  ;;
esac
done
}

advgetresponse ()
{
while echo -en "Please enter command (m for menu):\n:"
read response
do
case "$response" in
  1)
  #printf "\n\033[1;37Mirrorselect...\033[0m\n"
  mirrorselect
  printf "\n"
  continue
  advgetresponse
  ;;
  2)
  printf "\n\033[1;37mCleaning world...\033[0m\n"
  emerge -c
  continue
  advgetresponse
  ;;
  3)
  printf "\n"
  nano -w /var/cache/edb/world
  continue
  advgetresponse
  ;;
  4)
  printf "\n\033[1;37mRegenerating world mask...\033[0m\n"
  regenworld
  printf "\n"
  continue
  advgetresponse
  ;;
  e)
  menu
  break
  ;;
  c)
  SKIPPING=2
  catlog
  break
  ;;
  m)
  advmenu
  break
  ;;
  q)
  break
  ;;
esac
done
}

case "$1" in
  *)
  check_root
  ;;
esac

exit 0
