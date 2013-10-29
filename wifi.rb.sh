#!/usr/bin/ruby
require 'date'

# Config
@wifi_interface = 'en1' # en1 is the standard MacBook inteface
@hour = 17 # What time do you finish work?
@work_ssid = 'ACW Wifi'
@work_network = {
  ip_range: '192.168.',
  broadcast: '192.168.63.255'
}
@home_ssid = 'Cybertron'
@home_network = {
  ip_range: '192.168.0',
  broadcast: '192.168.0.255'
}

verbose_mode = ARGV.include?('-v')

# Requires airport command in path.
# /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport
#
# To add it, run
# sudo ln -s /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport /usr/bin/airport

# helper functions
def after_hour
  # Calculates a DateTime value for today at @hour hours (24-hour hour format).
  datetime_hour = DateTime.strptime(@hour.to_s + DateTime.now.strftime('%z'), '%H%z')
  datetime_hour <= DateTime.now
end

def turn_on_wifi
  # This turns en1 wifi device on
  `/usr/sbin/networksetup -setairportpower #{@wifi_interface} on`
end

def turn_off_wifi
  # This turns en1 wifi device off
  `/usr/sbin/networksetup -setairportpower #{@wifi_interface} off`
end

def turn_wifi(state = :on)
  if state == :on || state === true
    turn_on_wifi
  elsif state == :off || state === false
    turn_off_wifi
  end

  # Give the wifi a sec.
  sleep 1
end

def ssid_in_range(ssid)
  # Turn the wifi on if need be.
  was_wifi_on = wifi_state
  if !was_wifi_on
    turn_wifi
  end

  # `airport --scan=SSID` returns 'No networks found' when it cant find SSID
  !(`airport --scan=#{ssid}`.include?('No networks found'))

  if was_wifi_on != wifi_state
    turn_wifi(wifi_state)
  end
end

def connected_ipv4_networks
  # Returns connected ip4 networks from ifconfig
  `ifconfig | grep "inet "`
end

def on_network(network, need_wifi = false)
  was_wifi_on = wifi_state

  if was_wifi_on != need_wifi
    turn_wifi(need_wifi)
  end

  correct_ip_range = connected_ipv4_networks.include?(network[:ip_range])
  correct_broadcast = connected_ipv4_networks.include?(network[:broadcast])
  correct_ip_range && correct_broadcast

  if was_wifi_on != wifi_state
    turn_wifi(wifi_state)
  end
end

def wifi_state
  # `airport -I` returns 'AirPort: Off' if WiFi is off.
  !(`airport -I`.include?('AirPort: Off'))
end

# logic / process

was_wifi_on = wifi_state

log = []
log.push 'Wifi was ' + (was_wifi_on ? 'on' : 'off')

if !on_network(@work_network, false)
  log.push 'Not at work'
end

if after_hour
  log.push 'After ' + @hour.to_s
  if !ssid_in_range(@home_ssid)
    log.push 'home wifi (' + @home_ssid + ') is not in range'
  else
    log.push 'home wifi (' + @home_ssid + ') is in range'
  end

# If later than @hour and not on the work wired network, turn the wifi on.
elsif !on_network(@work_network, false)
  turn_wifi
end

log.push 'Wifi now ' + (wifi_state ? 'on' : 'off')

if verbose_mode
  puts log.join '; '
else
  puts log.last
end