# Ansible - Mailserver
## Description

Ansible role for setting up a mailserver. [Postfix](http://postfix.org) will be used as MTA, [dovecot](http://dovecot.org) for IMAP and POP3, and [amavis](http://www.amavis.org), [spamassassin](http://spamassassin.apache.org), [postgrey](http://postgrey.schweikert.ch/), and [clamav](http://www.clamav.net/) for spam and virus protection.

## Compatability

This role has been developed for use with *openSUSE* and has been tested against ansible 1.9.x.

## Variables

```yaml
---
##############################################################################
# Generic Settings
##############################################################################
apparmor_enabled: false
zabbix_agent: false

vmail_user: vmail
vmail_group: "{{ vmail_user}}"
vmail_uid: 5000
vmail_gid: "{{ vmail_uid }}"
vmail_home: /srv/vmail

# Local paths to certifacts to be copied to the mail server
src_ssl_cert_mail: ''
src_ssl_key_mail: ''


##############################################################################
# Postfix Settings
##############################################################################
# main.cf vars
myhostname: '{{ ansible_fqdn }}'
mydomain: '{{ primary_domain }}'
mynetworks: []
virtual_mailbox_domains: []
virtual_mailbox_base: "{{ vmail_home }}"
virtual_mailbox_maps: 'hash:/etc/postfix/vmailbox'
virtual_minimum_uid: 500
virtual_uid_maps: 'static:{{ vmail_uid }}'
virtual_gid_maps: 'static:{{ vmail_gid }}'
virtual_alias_maps: 'hash:/etc/postfix/virtual'
message_size_limit: 20480000

# SMTP AUTH configuration
smtpd_sasl_type: dovecot
smtpd_sasl_path: private/auth
smtpd_sasl_auth_enable: 'yes'
smtpd_sasl_security_options:
  - noanonymous
  - noplaintext

# Restrictions
# http://www.postfix.org/postconf.5.html#smtpd_helo_restrictions
smtpd_helo_restrictions:
  - permit_mynetworks
  - permit_sasl_authenticated
  - check_helo_access hash:/etc/postfix/helo_access
  - reject_invalid_helo_hostname
  - reject_non_fqdn_helo_hostname
  - warn_if_reject reject_unknown_helo_hostname

# http://www.postfix.org/postconf.5.html#smtpd_sender_restrictions
smtpd_sender_restrictions:
  - check_sender_access regexp:/etc/postfix/tag_as_originating.re
  - permit_mynetworks
  - permit_sasl_authenticated
  - check_sender_access regexp:/etc/postfix/tag_as_foreign.re
  - reject_non_fqdn_sender
  - reject_unknown_sender_domain

# http://www.postfix.org/postconf.5.html#smtpd_relay_restrictions
smtpd_relay_restrictions:
  - permit_mynetworks
  - permit_sasl_authenticated
  - reject_unauth_destination

# http://www.postfix.org/postconf.5.html#smtpd_recipient_restrictions
smtpd_recipient_restrictions:
  - reject_non_fqdn_recipient
  - reject_unknown_recipient_domain
  - permit_mynetworks
  - permit_sasl_authenticated
  - reject_unauth_destination
  - reject_rbl_client zen.spamhaus.org
  - reject_rhsbl_helo dbl.spamhaus.org
  - reject_rhsbl_sender dbl.spamhaus.org
  - 'check_policy_service unix:postgrey/socket'   # Enable greylisting through postgrey

# TLS certificate configuration
smtpd_tls_auth_only: 'yes'
smtpd_tls_security_level: may
smtpd_tls_cert_file: ''
smtpd_tls_key_file: ''
smtpd_sasl_tls_security_options: "{{ smtpd_sasl_security_options }}"
smtpd_tls_loglevel: 0
smtp_tls_security_level: may
smtp_tls_loglevel: 0

primary_domain: example.com
primary_email_address: user@example.com

# Values of the form:
#   user@example.com: example.com/user/
# These users must be in the virtual_aliases map as well due to the
# reject_sender_login_mismatch restriction in master.cf
virtual_mailboxes: {}

# Values of the form:
#   example.com:
#     alias: address
virtual_aliases: {}

##############################################################################
# Dovecot Settings
##############################################################################
dovecot_protocols:
  - imap
  - pop3
  - lmtp
mail_ssl_cert: "{{ smtpd_tls_cert_file }}"
mail_ssl_key: "{{ smtpd_tls_key_file }}"

# Users
# Generate with:
# doveadm pw -s sha512 -u <username>
# Values of the form:
#   user@example.com: '{SHA512}...'
dovecot_users: {}


##############################################################################
# Spam and Virus Protection
##############################################################################
# Amavisd Configuration
amavisd_max_servers: 2
amavisd_daemon_user: vscan
amavisd_daemon_group: '{{ amavisd_daemon_user }}'
amavisd_dkim_signature_options_bysender_maps:
  '.': "c => 'relaxed/simple', ttl => 21*24*3600"

# Used by helo_access.j2
public_ip: '{{ ansible_eth0["ipv4"]["address"] }}'

# Postgrey
postgrey_client_whitelist: []
postgrey_recipient_whitelist: []

# Freshclam settings
freshclam_mirror_country: de
```

For full details see `defaults/main.yml`.

The necessary AppArmor profiles can be automatically installed on AppArmor protected servers by setting `apparmor_enabled` to `true`. The Zabbix monitoring agent, with suitable configuration, can be installed by setting `zabbix_agent` to `true`.

## Contributors

Feel free to contribute by sending pull requests.

## License

This role is licensed under a BSD-style license. See LICENCE for details.
