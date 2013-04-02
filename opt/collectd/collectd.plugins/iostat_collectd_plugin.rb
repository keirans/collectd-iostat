#!/usr/bin/ruby
#
# iostat_collectd_plugin.rb
#
# This is a collectd plugin that calls iostat infinately every second.
# For each block device line, it uses ruby regex to reformat the required fields
# as required for collectd Exec plugins, of which it can then be graphed using one
# of the collectd write plugins, such as write graphite.
#
# Please see https://github.com/keirans/collectd-iostat/ for full details.
#
# A couple of notes about the format of the output that the collectd plugin requires:
#
# Collectd's exec plugin uses the plain text protocol to push data into collectd
# * Lines must begin with PUTVAL
# * The identifier string must contain a valid type reference that allows collectd
#   to be aware of the data type that is being provided.
#   In the case of this plugin we are using the gauge type, which is suitable for
#   positive and negative numbers.
# * The value we want to graph is printed in the N:<value> format. The N translates
#   to epoch time within collectd, followed by a colon and the value.
# * The iostat command runs with the _-Nxk_ options, as such,  all statistics are displayed
#   in kilobytes per second instead of blocks per second.
#   Don't forget this when you are building graphs and visualising your data.
#
# We trap the exit signal and then have it clean up all the children processes of the
# plugin. If we dont do this, we have orphaned iostat processes floating around on the server
# after a collectd restart. This isnt ideal.
#
# The plugin should run as nobody via the following exec plugin stanza
#
# <Plugin exec>
#    Exec "nobody" "/var/tmp/iostat_collectd_plugin.sh"
# </Plugin>
#
# Keiran S <Keiran@gmail.com>
#

trap("TERM") {cleanup_children_on_exit}

def cleanup_children_on_exit
    puts "Killing child process: " + @output.pid.to_s
    Process.kill("KILL", @output.pid)
    abort("Caught TERM exiting")
end

HOSTNAME = `hostname`.gsub(/\./, "_")

@output = IO.popen("iostat -Nxk 1")
    while line = @output.gets do
        if  ( line =~ /^(Linux|Time:|avg-cpu|Device| |$)/ )
            #puts "Debug: Skipped line:" + line
        else
            device, rrqm_sec,  wrqm_sec, r_s, w_s, rsec, wsec, avgrq_sz, avgqu_sz, await, svctm = line.split
            puts "PUTVAL " + HOSTNAME.chomp + "/iostatplugin/gauge-" + device + "/rrqm " + "N:" + rrqm_sec
            puts "PUTVAL " + HOSTNAME.chomp + "/iostatplugin/gauge-" + device + "/wrqm " + "N:" + wrqm_sec
            puts "PUTVAL " + HOSTNAME.chomp + "/iostatplugin/gauge-" + device + "/rs " + "N:" + r_s
            puts "PUTVAL " + HOSTNAME.chomp + "/iostatplugin/gauge-" + device + "/ws " + "N:" + w_s
            puts "PUTVAL " + HOSTNAME.chomp + "/iostatplugin/gauge-" + device + "/rsec " + "N:" + rsec
            puts "PUTVAL " + HOSTNAME.chomp + "/iostatplugin/gauge-" + device + "/wsec " + "N:" + wsec
            puts "PUTVAL " + HOSTNAME.chomp + "/iostatplugin/gauge-" + device + "/avgrqsz " + "N:" + avgrq_sz
            puts "PUTVAL " + HOSTNAME.chomp + "/iostatplugin/gauge-" + device + "/avgqusz " + "N:" + avgqu_sz
            puts "PUTVAL " + HOSTNAME.chomp + "/iostatplugin/gauge-" + device + "/await " + "N:" + await
            puts "PUTVAL " + HOSTNAME.chomp + "/iostatplugin/gauge-" + device + "/svctm " + "N:" + svctm
        end
    end

