#!/bin/sh

netstatResult=`netstat -rn | grep default`
set -- $netstatResult

if [ -z $2 ] || ! ping -oc 3 $2
	then
		echo gateway is down. you shall not pass. gateway address: $2
		exit 1
fi

logExists=false
sendDownMessageToWork=false

if [ -e ./isgitdown.templog ]
	then
		logData=$(head -n 1 ./isgitdown.templog)
		logExists=true
		IFS="|"
		set -- $logData
		downStartTime=$1
		lastMessageSentTime=$2

		echo downStartTime: $downStartTime
                echo lastMessageSentTime: $lastMessageSentTime
fi

echo log exists: $logExists

commandResult=`timeout 30 git ls-remote -h [git://gitrespository.git] [git branch that is always expected to be present] | grep -o [git ref that is always expected to be present]`

echo commandResult: $commandResult

if [ "$commandResult" = "[git ref that is always expected to be present]" ]
	then
		echo "GIT IS UP!"

		if [ $logExists = true ]
			then
				echo deleting templog file
				rm ./isgitdown.templog

				if [ ! -z $lastMessageSentTime ]
					then
						echo sending message to \#[slack channel]
						timeout 30 curl -X POST --data-urlencode 'payload={"channel": "#[slack channel]", "username": "[slack username]", "text": ":green_heart: GIT IS UP! :green_heart:"}' https://hooks.slack.com/services/[slack] &
						#send message to #[slack channel] that we're back up
				fi
		fi

		timeout 30 curl -X POST --data-urlencode 'payload={"channel": "#[slack channel]", "username": "[slack username]", "text": ":green_heart: GIT IS UP! :green_heart:"}' https://hooks.slack.com/services/[slack] &

	else

		echo "GIT IS DOWN!"
		currentTime=$(date +"%s")

		if [ $logExists = true ]
			then

				if [ ! -z $lastMessageSentTime ]
					then
						if [ $(echo "($currentTime - $lastMessageSentTime) / 60" | bc) -ge 30 ]
							then
								echo sending message to \#[slack channel] - git has been down 30 minutes since the last message was sent to \#[slack channel]
								sendDownMessageToWork=true
						fi

					else
						if [ ! -z $downStartTime ] && [ $(echo "($currentTime - $downStartTime) / 60" | bc) -ge 3 ]
							then
								echo sending message to \#[slack channel] - git has been down for 3 minutes
								sendDownMessageToWork=true
						fi
			
				fi

				if [ $sendDownMessageToWork = true ]
					then
						timeout 30 curl -X POST --data-urlencode 'payload={"channel": "#[slack channel]", "username": "[slack username]", "text": ":broken_heart: GIT IS DOWN! :broken_heart:"}' https://hooks.slack.com/services/[slack] &
                                                lastMessageSentTime=$currentTime
				fi

			else
				downStartTime=$currentTime
		fi

		timeout 30 curl -X POST --data-urlencode 'payload={"channel": "#[slack channel]", "username": "[slack username]", "text": ":broken_heart: GIT IS DOWN! :broken_heart:"}' https://hooks.slack.com/services/[slack] &

		echo $downStartTime"|"$lastMessageSentTime > isgitdown.templog

fi
