Collectd-iostat
====
Collectd-iostat is an iostat plugin for collectd that allows you to graph Linux iostat metrics in graphite or other output formats that are supported by collectd.

![Example browser](https://github.com/keirans/collectd-iostat/samples/images/graphite_screenshot.jpg)

How ?
-------
Written in simple Ruby, Collectd-iostat functions by calling iostat infinately each second and reformatting each block device line it into a layout suitable for the collectd Exec plugin.

Collectd can be then configured to write the collected data into many output formats that are supported by it's write plugins, such as graphite, which was the primary use case for this plugin.

Why ?
-------
This was written to assist in debugging an issue where block device throughput and utilisation was being blamed for poor application performance, which this plugin showed this was not the case. 
Although collectd provides disk statistics out of the box, graphing the metrics as shown by iostat was found to be more useful for this particular issue as the metrics graphed matched those seen by the end users in their userland tools with minimal conversion of values, and it also was more granular in functionality, in that metrics are provided on block devices, partitions, multipath devices and LVM volumes.

In addition to this, it was also used as a chance to learn a bit of ruby.

Setup
-------
Deploy the collectd ruby plugin into a suitable plugin directory for your collectd instance. 

Configure collectd's Exec plugin to execute the iostat plugin using a stanza similar to the following: 


    <Plugin exec>
        Exec "nobody" "/opt/collectd/collectd.plugins/iostat_collectd_plugin.rb"
    </Plugin>
               

Once functioning, the iostat data should then be visible via your various output plugins. 

In the case of Graphite, collectd should be writing data to graphite in the *hostname_domain_tld.iostatplugin.gauge-DEVICE.column-name* style namespace that isnt very pretty, because of this, it is worth applying some rewrite rules to clean up the namespacing a little for ease of use, some of these rules have been included for reference to assist in setting this up, see the _rewrite-rules.conf_ file for more information.

Technical notes
-------
Collectd's exec plugin uses the plain text protocol to push data into collectd, to acheive this the plugin adheres to the following format: 

*  Lines must begin with PUTVAL 
*  The identifier string must contain a valid type reference that allows collectd to be aware of the data type that is being provided.  
   In the case of this plugin we are using the gauge type, which is suitable for positive and negative integers. 
*  The value we want to graph is printed in the N:<value> format. The N translates to epoch time within collectd, followed by a colon and the value. 
*  The iostat command runs with the _-Nxk_ options, as such,  all statistics are displayed in kilobytes per second instead of blocks per second.
   Don't forget this when you are building graphs and visualising your data.


It is also worth noting that Graphite can graph metrics sent to it down to a very granular level, however it is often the case that iostat can not provide this plugin data every second, especially in the case of servers with a large number of block devices where additional overhead may occur. 
Because of this, you may struggle to get iostat metrics every second, and may in fact be every 1-3 seconds, as such, you should tune your carbon/whisper configuration accordingly after testing.




Additional reading
-------
* [Graphite @ The Architecture of Open Source Applications](http://www.aosabook.org/en/graphite.html)

* [Custom Collectd Plug-ins for Linux](http://support.rightscale.com/12-Guides/RightScale_101/08-Management_Tools/Monitoring_System/Writing_custom_collectd_plugins/Custom_Collectd_Plug-ins_for_Linux) 

* [The Collectd Plain text protocol](https://collectd.org/wiki/index.php/Plain_text_protocol)

* [The Collectd Exec plugin](https://collectd.org/wiki/index.php/Plugin:Exec)


Contact
-------
[@keiran_s](http://twitter.com/keiran_s) || [Email - Keiran](mailto:keiran@gmail.com)