#!/bin/bash
checklog ()
{
LOG=$(ls $PWD | grep goz_transferer.log)
if [ -z $LOG ]; then
   touch ${PWD}/goz_transferer.log
   echo "goz_transferer.log created" | tee -a ${PWD}/goz_transferer.log
fi
}

getfund ()
{
for FUND in $FUNDS
do
   BAL=$(rly q bal $FUND | awk -F '[a-z][A-z]' '{print $1}')
   if [ -z $BAL ]; then
      echo "cant connect to $FUND" | tee -a ${PWD}/goz_transferer.log
   elif [ $BAL -lt "200000" ]; then
      echo "fund ends $BAL you need to get money from $FUND" #|ts| tee -a ${PWD}/goz_transferer.log
      if [ "$FUND" == "flint" ]; then
         rly tst req $FUND -u $FAUCET
      else
         rly tst req $FUND  # | ts | tee -a ${PWD}/goz_transferer.log
      fi                                                                                                                                                                                                                                     
   fi                                                                                                                                                                                                                                        
done                                                                                                                                                                                                                                         
}                                                                                                                                                                                                                                            
                                                                                                                                                                                                                                             
                                                                                                                                                                                                                                             
client-update ()                                                                                                                                                                                                                             
{                                                                                                                                                                                                                                            
for PTH in $PATHS                                                                                                                                                                                                                            
do                                                                                                                                                                                                                                           
   NAME=$(echo $PTH | awk -F ':' '{print $1}')                                                                                                                                                                                                  
   CHANELNAME=$(echo $PTH | awk -F ':' '{print $2}' | awk -F ';' '{print $1}')                                                                                                                                                                                                                                                                                                                                         
   ID1=$(rly pth show $CHANELNAME | grep -A 1 $GAMEOF | grep 'ClientID' | awk -F ':' '{print $2}'| sed 's/ //g')                                                                                                                                
   ID2=$(rly pth show $CHANELNAME | grep -A 1 $NAME | grep 'ClientID' | awk -F ':' '{print $2}'| sed 's/ //g')
   echo "execute rly tx raw update-client $NAME $GAMEOF $ID2" | ts |tee -a ${PWD}/goz_transferer.log
   while true; do
      STATE=$(rly tx raw update-client $NAME $GAMEOF $ID2 -d | jq .height 2>/dev/null | sed 's/"//g')
      echo $STATE | ts | sed -e 's/$/ block/' |tee -a ${PWD}/goz_transferer.log
      if [ -z $STATE ]; then
         curl -s -X POST https://api.telegram.org/bot$BOTNUMBER1/sendMessage -d chat_id=$CHATID -d text="LAST $NAME CLIENT NOT UPDATED"
         sleep 3;
         continue;
      elif [ "$STATE" -eq "0" ]; then
         curl -s -X POST https://api.telegram.org/bot$BOTNUMBER1/sendMessage -d chat_id=$CHATID -d text="LAST $NAME CLIENT NOT UPDATED"
         sleep 3; 
         continue;   
      else
         break;
      fi
done

   echo "execute rly tx raw update-client $GAMEOF $NAME $ID1" | ts |tee -a ${PWD}/goz_transferer.log
   while true; do
      STATE1=$(rly tx raw update-client $GAMEOF $NAME $ID1 -d | jq .height 2>/dev/null | sed 's/"//g')
      echo $STATE1 | ts | sed -e 's/$/ block/' |tee -a ${PWD}/goz_transferer.log
      if [ -z $STATE1 ]; then
         curl -s -X POST https://api.telegram.org/bot$BOTNUMBER1/sendMessage -d chat_id=$CHATID -d text="LAST $NAME CLIENT NOT UPDATED"
         sleep 3;
         continue;
      elif [ "$STATE1" -eq "0" ]; then
         curl -s -X POST https://api.telegram.org/bot$BOTNUMBER1/sendMessage -d chat_id=$CHATID -d text="LAST $GAMEOF CLIENT NOT UPDATED"
         sleep 3; 
         continue;
      else
         break;
      fi
   done

rly q bal $GAMEOF | ts |tee -a ${PWD}/goz_transferer.log
done
}

transfer()
{
for PTH in $PATHS; do
   NAME=$(echo $PTH | awk -F ':' '{print $1}')
   CHANELNAME=$(echo $PTH | awk -F ':' '{print $2}' | awk -F ';' '{print $1}')

   for (( ITER=1; ITER<=10; ITER++ )); do
      TR=$(rly tx transfer $GAMEOF $NAME 10${DENOM} true $(rly ch addr $NAME))
      if [ "$(echo $TR | awk -F "$GAMEOF" '{print $2}' | awk -F '-' '{print $1}' | sed 's/\]//g' |sed 's/\@//g'| sed 's/{//g'| sed 's/}//g')" -eq "0" ]; then
         rly tx rly $CHANELNAME | tee -a ${PWD}/goz_transferer.log
         sleep 3
         continue;
      else
         break; 
      fi
   done

echo $TR | tee -a ${PWD}/goz_transferer.log

rly q bal $GAMEOF | tee -a ${PWD}/goz_transferer.log
done
}

xref()
{
for PTH in $PATHS; do
   NAME=$(echo $PTH | awk -F ':' '{print $1}')
   CHANELNAME=$(echo $PTH | awk -F ':' '{print $2}' | awk -F ';' '{print $1}')
   for (( ITER=1; ITER<=10; ITER++ )); do
      XF=$(rly tx xfer $NAME $GAMEOF 1${DENOM} false $(rly ch addr $GAMEOF))
      if [ "$(echo $XF | awk -F "$NAME" '{print $2}' | awk -F '-' '{print $1}' | sed 's/\]//g' |sed 's/\@//g'| sed 's/{//g'| sed 's/}//g')" -eq "0" ]; then
         rly tx rly $CHANELNAME | tee -a ${PWD}/goz_transferer.log
         sleep 3
         continue;
      else
         break;
      fi
   done

echo $XF | tee -a ${PWD}/goz_transferer.log
rly q bal $NAME | tee -a ${PWD}/goz_transferer.log
done
}

DENOM=doubloons
GAMEOF=gameofzoneshub-1b
EVERSTAKE=everstakechain-1b
FUNDS="everstakechain-1b"
PATHS="everstakechain-1b:game3;cosmos1zt57587dk595090gdtsy"
CHATID=541111140
BOTNUMBER1=11111111:AAFoOdfgdfdgdgfdfWuEQ
FAUCET="http://faucet_ip:faucet:port"

while true; do
   checklog
   getfund
   client-update
   sleep 120
   #transfer
   #xref
done
