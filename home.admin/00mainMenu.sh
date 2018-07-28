#!/bin/bash

## default menu settings
HEIGHT=11
WIDTH=64
CHOICE_HEIGHT=4
BACKTITLE="RaspiBlitz"
TITLE=""
MENU="Choose one of the following options:"
OPTIONS=()

# default config values (my get changed later)
if [ ! -f ./.network ]; then
  echo "bitcoin" > /home/admin/.network
fi
network=`cat .network`

## get actual setup state
setupState=0;
if [ -f "/home/admin/.setup" ]; then
  setupState=$( cat /home/admin/.setup )
fi
if [ ${setupState} -eq 0 ]; then

    # start setup
    BACKTITLE="RaspiBlitz - Setup"
    TITLE="⚡ Welcome to your RaspiBlitz ⚡"
    MENU="\nChoose how you want to setup your RaspiBlitz: \n "
    OPTIONS+=(BITCOIN "Setup BITCOIN and Lightning (DEFAULT)" \
              LITECOIN "Setup LITECOIN and Lightning (EXPERIMENTAL)" )
    HEIGHT=11

elif [ ${setupState} -lt 100 ]; then

    # continue setup
    BACKTITLE="RaspiBlitz - Setup"
    TITLE="⚡ Welcome to your RaspiBlitz ⚡"
    MENU="\nThe setup process in snot finished yet: \n "
    OPTIONS+=(CONTINUE "Continue Setup of your RaspiBlitz")
    HEIGHT=10

else

    # make sure to have a init pause aufter fresh boot
    uptimesecs=$(awk '{print $1}' /proc/uptime | awk '{print int($1)}')
    waittimesecs=$(expr 150 - $uptimesecs)
    if [ ${waittimesecs} -gt 0 ]; then
      dialog --pause "  Waiting for ${network} to startup and init ..." 8 58 ${waittimesecs}
    fi

    # MAIN MENU AFTER SETUP

    chain=$(${network}-cli -datadir=/home/bitcoin/.${network} getblockchaininfo | jq -r '.chain')
    locked=$(sudo tail -n 1 /mnt/hdd/lnd/logs/${network}/${chain}net/lnd.log | grep -c unlock)
    if [ ${locked} -gt 0 ]; then

      # LOCK SCREEN
      MENU="!!! YOUR WALLET IS LOCKED !!!"
      OPTIONS+=(X "Unlock your Lightning Wallet with 'lncli unlock'")

    else

     # REGULAR MENU
      OPTIONS+=(INFO "RaspiBlitz Status Screen" \
		lnbalance "Detailed Wallet Balances" \
        lnchannels "Lightning Channel List")

    fi

fi

CHOICE=$(dialog --clear \
                --backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${OPTIONS[@]}" \
                2>&1 >/dev/tty)

clear
case $CHOICE in
        CLOSE)
            exit 1;
            ;;
        BITCOIN)
            echo "bitcoin" > /home/admin/.network
            ./10setupBlitz.sh
            exit 1;
            ;;
        LITECOIN)
            echo "litecoin" > /home/admin/.network
            ./10setupBlitz.sh
            exit 1;
            ;;
        CONTINUE)
            ./10setupBlitz.sh
            exit 1;
            ;;
        INFO)
            ./00infoBlitz.sh
            echo "Screen is not updating ... press ENTER to continue."
            read key
            ./00mainMenu.sh
            ;;
        lnbalance)
            lnbalance
            echo "Press ENTER to return to main menu."
            read key
            ./00mainMenu.sh
            ;;
        lnchannels)
            lnchannels
            echo "Press ENTER to return to main menu."
            read key
            ./00mainMenu.sh
            ;;
        X) # unlock
            ./AAunlockLND.sh
            ./00mainMenu.sh
            ;;
esac
