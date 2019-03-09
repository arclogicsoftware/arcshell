# How to install and configure sSMTP.

Notes on getting SSMTP installed on an Ubuntu VM.

## References
* https://help.hover.com/hc/en-us/articles/217281777-Email-server-settings-
* https://wiki.freebsd.org/SecureSSMTP

Install the ```ssmtp``` program.
```bash
sudo apt install ssmtp
```
Example working configuration file. You will need to use Gmail to generate a secret password for this application.

```bash
ethan@devgame:/etc$ sudo cat /etc/ssmtp/ssmtp.conf
#
# Config file for sSMTP sendmail
#
# The person who gets all mail for userids < 1000
# Make this empty to disable rewriting.
root=postmaster

# The full hostname
hostname=devgame

# Are users allowed to set their own From: address?
# YES - Allow the user to specify their own From: address
# NO - Use the system generated From: address
FromLineOverride=YES

AuthUser=me@gmail.com
AuthPass=djjedjdewwebfryu
mailhub=smtp.gmail.com:587
UseSTARTTLS=YES
```


