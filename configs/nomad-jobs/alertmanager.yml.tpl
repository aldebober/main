global:
  # The smarthost and SMTP sender used for mail notifications.
  smtp_smarthost: 'smtp.gmail.com:465'
  smtp_from: 'alertmanager@simplinic.com'
  smtp_auth_username: ''
  smtp_auth_password: ''
  # The auth token for Hipchat.
  hipchat_auth_token: '1234556789'
  # Alternative host for Hipchat.
  hipchat_url: 'https://hipchat.foobar.org/'
  slack_api_url: '{{ env "slack_url"}}'

# The directory from which notification templates are read.
templates: 
- 'alertmanager/template/*.tmpl'

# The root route on which each incoming alert enters.
route:
  # The labels by which incoming alerts are grouped together. For example,
  # multiple alerts coming in for cluster=A and alertname=LatencyHigh would
  # be batched into a single group.
  group_by: ['alertname', 'cluster', 'service']

  # When a new group of alerts is created by an incoming alert, wait at
  # least 'group_wait' to send the initial notification.
  # This way ensures that you get multiple alerts for the same group that start
  # firing shortly after another are batched together on the first 
  # notification.
  group_wait: 30s

  # When the first notification was sent, wait 'group_interval' to send a batch
  # of new alerts that started firing for that group.
  group_interval: 5m

  # If an alert has successfully been sent, wait 'repeat_interval' to
  # resend them.
  repeat_interval: 3h 

  # A default receiver
  receiver: slack

  # All the above attributes are inherited by all child routes and can 
  # overwritten on each.

  # The child route trees.
  routes:
  # This routes performs a regular expression match on alert labels to
  # catch alerts that are related to a list of services.
  - match_re:
      service: ^(foo1|foo2|baz)$
    receiver: test-mails
    # The service has a sub-route for critical alerts, any alerts
    # that do not match, i.e. severity != critical, fall-back to the
    # parent node and are sent to 'team-X-mails'
  - receiver: 'pagerduty'
    group_wait: 10s
    match_re:
      service: 'vernemq'

receivers:
- name: 'test-mails'
  email_configs:
  - to: 'yurix@mail.com'
- name: 'pagerduty'
  pagerduty_configs:
  - service_key: {{ env "slack_key"}}
- name: 'slack'
  slack_configs:
  - api_url: '{{ env "slack_url"}}'
  - channel: 'tech_alerts'
