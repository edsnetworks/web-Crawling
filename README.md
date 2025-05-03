basic usage: install crawl4ai, I've used official docker image. Once installed you shoud see the webpage http://localhost:11235/playground or from different computer http://"your-server-ip":11235/playground.
copy the script and replace "your-server-ip" at the 4th line with the ip of your crawler with nano or vim.
save the script and make it executable with sudo chmod +x crawl4ai.sh
run it and when asked paste the sitemap.xml you want srape.
wait until is finished
and output directory is /output in the same folder you run it.
enjoy
tested on different websites  with 16kpages and the result are precise, clean and zero waste of data. The little difference from cheerio and other raw crawler is the filter html2text: is a good reasonable choice that convert the raw format in clear text.
