#!/bin/sh
######################
# stealthMode Sunset #
######################
#
# Turn off/on all LEDs based on sun set for Asus routers which uses ASUSWRT-Merlin firmware
#
# Version: 1.0 "Sunset"
# Author : Monter (http://monter.techlog.pl)
#

# this makes you put and call script where / how you want
dir=`/bin/echo $( cd "$(/usr/bin/dirname "$0")" ; /bin/pwd -P )`
stms=`/usr/bin/basename ${0}`

# firmware check
IFMERLIN=`/bin/cat /etc/motd | /bin/grep "ASUSWRT-Merlin" | /usr/bin/wc -l`

# LEDs status
ISLEDSON=`/bin/nvram get led_disable`

# Go!
if /usr/bin/[ "$IFMERLIN" = "1" ]; then

    case "$1" in
        on)
            if /usr/bin/[ "$ISLEDSON" = "0" ]; then
              /usr/bin/logger -p6 -s -t stealthMode Activated
              /bin/nvram set led_disable=1
              /sbin/service restart_leds > /dev/null 2>&1
            else
              /usr/bin/logger -p6 -s -t stealthMode It\'s currently enabled!
            fi
        ;;
        sun)
            if /usr/bin/[ "$2" != "" -a "0$(/bin/echo $2 | /usr/bin/tr -d ' ')" -ge 0 ] 2>/dev/null; then
                /usr/bin/logger -p6 -s -t stealthMode Sunset Enabled
                /usr/sbin/cru a stealthsun_on "0 2 * * * $dir/$stms sun_on $2"
                $dir/$stms sun_on $2
            else
                /usr/bin/logger -p3 -s -t stealthMode Sunset error - the city code does not specified!
                $dir/$stms
                exit 1
            fi
        ;;
        sun_on)
            # check internet connection
            CONERR=1
            # ping for check internet connection
            YAHOOAPIS="weather.yahooapis.com"
            if /usr/bin/[ `/bin/echo $YAHOOAPIS | /usr/bin/wc -c` -gt 2 ]; then
              /bin/ping -q -w 1 -c 1 $YAHOOAPIS > /dev/null
              if /usr/bin/[ $? == 0 ]; then CONERR=0; fi
            fi
            # result of internet connection check
            if /usr/bin/[ "$CONERR" -ne 0 ] ; then
                /usr/bin/logger -p3 -s -t stealthMode Sunset error - no active Internet connection!
                $dir/$stms
                exit 1
            else
                if /usr/bin/[ "$2" != "" -a "0$(/bin/echo $2 | /usr/bin/tr -d ' ')" -ge 0 ] 2>/dev/null; then
                    $dir/$stms sch_clear # clear scheduled tasks when sunset is enabled
                    sun=`l=$2;/usr/bin/wget -q -O - http://weather.yahooapis.com/forecastrss?w=$l | /bin/grep astronomy | /usr/bin/awk -F\" '{print $4}' | /usr/bin/awk -F\" '{split($1, A, " ");split(A[1], B, ":");HR=B[1];MIN=B[2];if(A[2] == "pm") HR+=12;$1=sprintf("%d %d", MIN, HR);}1'`
                    if /usr/bin/[ "$sun" = "" ] ; then /usr/bin/logger -p3 -s -t stealthMode Weather sunset time error!; exit 1; else /usr/sbin/cru a stealthsunset $sun "* * * $dir/$stms on"; fi
                    sur=`l=$2;/usr/bin/wget -q -O - http://weather.yahooapis.com/forecastrss?w=$l | /bin/grep astronomy | /usr/bin/awk -F\" '{print $2}' | /usr/bin/awk -F\" '{split($1, A, " ");split(A[1], B, ":");HR=B[1];MIN=B[2];if(A[2] == "pm") HR+=12;$1=sprintf("%d %d", MIN, HR);}1'`
                    if /usr/bin/[ "$sur" = "" ] ; then /usr/bin/logger -p3 -s -t stealthMode Weather sunrise time error!; exit 1; else /usr/sbin/cru a stealthsunrise $sur "* * * $dir/$stms off"; fi
                    /usr/bin/logger -p6 -s -t stealthMode Sunset city code: $2, sunset: $( /bin/echo $sun | /usr/bin/awk '{$1=sprintf("%02d", $1); $2=sprintf("%02d", $2); print $2":"$1 }' ), sunrise: $( /bin/echo $sur | /usr/bin/awk '{$1=sprintf("%02d", $1); $2=sprintf("%02d", $2); print $2":"$1 }' )
                    HOUR=$(/bin/date +%k); SUNRUN=$( /bin/echo $sun | /usr/bin/awk '{ print $2 }' ); SURRUN=$( /bin/echo $sur | /usr/bin/awk '{ print $2 }' ); if /usr/bin/[ "$HOUR" -ge "$SURRUN" -a "$HOUR" -le "$SUNRUN" ] ; then
                        /usr/bin/logger -p6 -s -t stealthMode The time now is $( /bin/date +%H:%M), so StealthMode will be activated on the next sunset
                    else
                        $dir/$stms on
                    fi
                else
                    /usr/bin/logger -p3 -s -t stealthMode Sunset error - the city code does not specified!
                    $dir/$stms
                    exit 1
                fi
            fi
        ;;
        sun_off)
            /usr/bin/logger -p6 -s -t stealthMode Sunset Disactivated
            /usr/sbin/cru d stealthsun_on
            /usr/sbin/cru d stealthsunset
            /usr/sbin/cru d stealthsunrise
            $dir/$stms off
        ;;
        sch_on)
            if /usr/bin/[ "${2}" != "" -a "${2}" -le 23 -a "0$(/bin/echo $2 | /usr/bin/tr -d ' ')" -ge 0 ] 2>/dev/null; then
              if /usr/bin/[ "${3}" != "" -a "${3}" -le 59 -a "${3}" -eq "${3}" ] 2>/dev/null; then SCHMIN=${3}; else SCHMIN="0"; fi
              /usr/sbin/cru a stealthsheduleon $SCHMIN $2 "* * * $dir/$stms on"
              /usr/bin/logger -p6 -s -t stealthMode Scheduled On set to $2:$(/usr/bin/printf "%02d" $SCHMIN)
            else
              /usr/bin/logger -p3 -s -t stealthMode Scheduled On error - Hour / Minutes does not specified!
              $dir/$stms
              exit 1
            fi
        ;;
        sch_off)
            if /usr/bin/[ "${2}" != "" -a "${2}" -le 23 -a "0$(/bin/echo $2 | /usr/bin/tr -d ' ')" -ge 0 ] 2>/dev/null; then
              if /usr/bin/[ "${3}" != "" -a "${3}" -le 59 -a "${3}" -eq "${3}" ] 2>/dev/null; then SCHMIN=${3}; else SCHMIN="0"; fi
              /usr/sbin/cru a stealthsheduleoff $SCHMIN $2 "* * * $dir/$stms off"
              /usr/bin/logger -p6 -s -t stealthMode Scheduled Off set to $2:$(/usr/bin/printf "%02d" $SCHMIN)
            else
              /usr/bin/logger -p3 -s -t stealthMode Scheduled Off error - Hour / Minutes does not specified!
              $dir/$stms
              exit 1
            fi
        ;;
        sch_clear)
            SON=`/usr/sbin/cru l | /bin/grep stealthsheduleon | /usr/bin/wc -l`
            SOFF=`/usr/sbin/cru l | /bin/grep stealthsheduleoff | /usr/bin/wc -l`
            if /usr/bin/[ "$SON" = "1" -o "$SOFF" = "1" ]; then
              /usr/sbin/cru d stealthsheduleon
              /usr/sbin/cru d stealthsheduleoff
              /usr/bin/logger -p6 -s -t stealthMode Scheduler Tasks Deleted
            fi
        ;;
        clear_all)
            $dir/$stms sun_off
            $dir/$stms sch_clear
            /usr/bin/logger -p6 -s -t stealthMode Complete shutdown and delete all jobs from Crontab - done
        ;;
        off)
            /bin/nvram set led_disable=0
            /sbin/service restart_leds > /dev/null 2>&1
            /usr/bin/logger -p6 -s -t stealthMode Disactivated
        ;;
        *)
            /bin/echo "stealthMode Sunset v1.0 by Monter [released on 29.12.2014]"
            /usr/bin/logger -p1 -s -t Usage "$stms {on|off|sun <city_code>|sun_off|sch_on <H> <M>|sch_off <H> <M>|sch_clear|clear_all}"
            /bin/echo
            /bin/echo " [Standard mode]"
            /bin/echo "   on | off        - enable or disable steathMode in real time"
            /bin/echo
            /bin/echo " [Sunset mode]"
            /bin/echo "   sun <city_code> - will daily get the sunrise and sunset times of a specific"
            /bin/echo "                     location automatically and activate Sunset mode"
            /bin/echo "                     To be able to determine your <city_code> you need to first"
            /bin/echo "                     go to http://weather.yahoo.com/ and look up your location"
            /bin/echo "                     The last NUMBERS in the URL will be your <city_code>"
            /bin/echo "                     Example: \"$stms sun 514048\" if you live in Poznan/Poland ;)"
            /bin/echo "                     This feature requires a working Internet connection"
            /bin/echo "   sun_off         - fully deactivate Sunset mode"
            /bin/echo
            /bin/echo " [Scheduled mode]"
            /bin/echo "   sch_on <H> <M>  - set the hour and minutes of the scheduled enable/disable"
            /bin/echo "   sch_off <H> <M>   stealthMode in Standard mode and adding jobs to the Crontab"
            /bin/echo "                     Hour and minute time must be a numbers without any additional"
            /bin/echo "                     characters, where hour is a mandatory parameter, while not"
            /bin/echo "                     specifying an minute will assign a default 00 value"
            /bin/echo "                     These options add just the right job for Crontab, nothing more"
            /bin/echo "   sch_clear       - removes tasks from Crontab for scheduled enable/disable"
            /bin/echo "                     stealthMode function set by sch_on and sch_off switches"
            /bin/echo
            /bin/echo " [Repair / debug]"
            /bin/echo "   clear_all       - removes all jobs from Crontab and completely disables all"
            /bin/echo "                     available stealthMode modes"
            /bin/echo
            /bin/echo " Send your bug report to monter[at]techlog.pl"
            exit 1
    esac
else
    /usr/bin/logger -p3 -s -t stealthMode Router does not support this feature. StealthMode works only in Asus with ASUSWRT-Merlin firmware.
fi
