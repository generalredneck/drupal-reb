; Use this file to build a full distribution including Drupal core and the
; Commerce Kickstart install profile using the following command:
;
; drush make distro.make <target directory>

api = 2
core = 7.x

; Drupal core specification.
includes[] = drupal-org-core.make

projects[reb][type] = profile
projects[reb][download][type] = git
projects[reb][download][url] = https://github.com/generalredneck/drupal-reb.git
projects[reb][download][branch] = master
