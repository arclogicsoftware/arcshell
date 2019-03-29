

if [[ -d ./arcshell ]]; then
	echo "Please remove the 'arcshell' directory and try again."
	exit 1
fi

if [[ -d "./arcshell-master" ]]; then
	echo "Please remove the 'arcshell-master' directory and try again."
	exit 1
fi

wget https://github.com/arclogicsoftware/arcshell/archive/master.zip
unzip master.zip
mv arcshell-master arcshell
find "./arcshell" -type f -name "*.sh" -exec chmod 700 {} \;
cd arcshell || exit 1

./arcshell_setup.sh
