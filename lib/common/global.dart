import 'package:flutter/cupertino.dart';
import 'package:jenkins_app/models/jenkins.dart';
import 'package:jenkins_app/models/jenkins_shipla.dart';
import 'package:jenkins_app/models/jenkins_wms_be.dart';
import 'package:jenkins_app/models/jenkins_wms_fe.dart';

const wmsNewApiPhp = 'wms_new_api-php';
const wmsScmApiPhp = 'wms_scm_api-php';
const wmsBossApi = 'wms_boss_api';

const wmsUi = 'wms-ui';
const wmsBossUi = 'wms_boss_ui';

const shiplaCt = 'shipla-ct';
const shiplaGo = 'shipla-go';
const shiplaWeb = 'shipla-web';

JenkinsProjectModel getInstance(BuildContext context, JenkinsModel jenkins, String name) {
  if ([wmsNewApiPhp, wmsScmApiPhp, wmsBossApi].contains(name)) {
    return JenkinsWmsBe(context, jenkins, name: name);
  }

  if ([wmsUi, wmsBossUi].contains(name)) {
    return JenkinsWmsFe(context, jenkins, name: name);
  }

  if ([shiplaCt, shiplaGo, shiplaWeb].contains(name)) {
    return JenkinsShipla(context, jenkins, name: name);
  }

  return JenkinsProjectModel(name: '');
}
