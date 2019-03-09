# How to install and configure postfix.

This is the system I used to get enable outbound email from an Azure Ubuntu VM using a Hover email server.

## References
* https://help.hover.com/hc/en-us/articles/217281777-Email-server-settings-
* https://www.linode.com/docs/email/postfix/postfix-smtp-debian7/
* http://www.postfix.org/BASIC_CONFIGURATION_README.html

Install the following programs.
```bash
# Debian
sudo apt-get install libsasl2-modules
sudo apt install mailutils
sudo apt-get install postfix

# RedHat
sudo yum install postfix
```
If using Debian copy the template to ```main.cf``` file.
```bash
sudo cp /usr/share/postfix/main.cf.debian /etc/postfix/main.cf
```
Create the ```/etc/postfix/sasl_passwd``` file. Ports 465 and 587 both worked. 465 should be secure however.
```bash
arclogic@azure:/etc/postfix$ sudo cat /etc/postfix/sasl_passwd
[mail.hover.com]:465 myusername:mypassword
```
The contents of a working ```/etc/postfix/main.cf``` file.
```bash
# See /usr/share/postfix/main.cf.dist for a commented, more complete version

# Debian specific:  Specifying a file name will cause the first
# line of that file to be used as the name.  The Debian default
# is /etc/mailname.
#myorigin = /etc/mailname

smtpd_banner = $myhostname ESMTP $mail_name (Ubuntu)
biff = no

# appending .domain is the MUA's job.
append_dot_mydomain = no

# Uncomment the next line to generate "delayed mail" warnings
#delay_warning_time = 4h

readme_directory = no

# See http://www.postfix.org/COMPATIBILITY_README.html -- default to 2 on
# fresh installs.
compatibility_level = 2

# specify SMTP relay host
relayhost = [mail.hover.com]:465

# enable SASL authentication
smtp_sasl_auth_enable = yes
# disallow methods that allow anonymous authentication.
smtp_sasl_security_options = noanonymous
# where to find sasl_passwd
smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd
# Enable STARTTLS encryption
smtp_use_tls = yes
# where to find CA certificates
smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt
smtp_tls_wrappermode = yes
smtp_tls_security_level = encrypt
```
Creates and secures the ```sasl_passwd.db``` file.
```bash
sudo postmap /etc/postfix/sasl_passwd
sudo chown root:root /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
sudo chmod 0600 /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db
```
Make sure you restart postfix anytime you make changes.
```bash
sudo service postfix restart
```
You can monitor the mail service by tailing the mail log in the background.
```bash
tail -f /var/log/mail.log &
```
Send a test mail.
```bash
echo foo | mail -a "From: ${LOGNAME}@$(hostname)" -s "Hello World" bar@acme.com
```

