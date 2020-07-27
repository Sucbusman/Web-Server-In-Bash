#!/usr/bin/env bash
# curl http://www.gnu.org/licenses/gpl-3.0.txt
if [ 1"$1" == "1perRequest" ];then
	OK="HTTP/1.0 200 OK\r"
	NOTFOUND="HTTP/1.0 404 Not Found\r"
	SERVER="Server: shellfool\r"
	html_head="<html><center><h style='color: blueviolet;'>File List</h><hr/>"
	html_tail="<hr/><p style='color: aqua;'onclick='history.go(-1)'>Back</p></center></html>"
	html_type="text/html;charset=utf-8"
	send(){
		local length="$(echo -n "$3"|wc -c)"
		echo -e $1
		echo -e $SERVER
		echo -e "Content-Type:$2\r"
		echo -e "Content-Length:$length\r\n\r"
		echo "$3"
		echo -e "\r"
	}
	sendfile(){
		local fname=$1
		if [ ${#fname} -gt 1 ];then
			fname=${fname:1:${#fname}}
		fi
		if [ -d $fname ];then
			if [ $fname != "/" ];then
				fname=$fname/
			fi
			#use different slash when directory or file
			data="$html_head"
			fname=./$fname
			cd $fname
			for i in $(ls) ;do
				if [ -d $i ];then
					data+="<a href='$i/'>$i</a><br/>"
				else
					data+="<a href='$i'>$i</a><br/>"
				fi
			done
			cd - >&/dev/null
			data+="$html_tail"
			send "$OK" "$html_type" "$data"
			return
		else
			fname=./$fname
			if [ -f $fname ];then
				if [ -r $fname ];then
					local method=$OK
					local ctype="$(/usr/bin/file -bi $fname)"
					local data=$(cat $fname)
					send "$OK" "$ctype" "$data"
					return
				fi
			fi
		fi
		send "$NOTFOUND" "$html_type" "Sry,Not Found"
	}
	read -r request
	fname="$(echo $request|awk -e '{print $2}')"
	if [ -z $fname ];then
		send "$NOTFOUND" "$html_type" "Sry,Not Found"
	else
		fname=${fname//../}
		while true;do
			read -r header
			header=${header%%$'\r'}
			[ -z "$header" ] && break
		done
		sendfile $fname
	fi
elif [ -z "$1" ];then
	echo "usage:"$0" port(default 8888)"
else
	if grep '^[[:digit:]]*$'>&/dev/null <<< "$1";then
		port="$1"
	else
		echo "use default port 8888"
		port=8888
	fi
	pipe=/tmp/shellfool$RANDOM
	rm -f $pipe;mkfifo $pipe
	echo ">>>Simple File Server In Bash<<<"
	netcatExec(){
		cat $pipe | $1 | nc -lp $port > $pipe
		return 0
	}
	while netcatExec "$0 perRequest";do
		echo -e "[+] $(date), A client connect"
	done
	rm -f $pipe
fi
