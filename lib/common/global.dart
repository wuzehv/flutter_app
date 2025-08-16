import 'package:flutter/cupertino.dart';
import 'package:jenkins_app/models/jenkins.dart';
import 'package:jenkins_app/models/jenkins_wms_be.dart';
import 'package:jenkins_app/models/jenkins_wms_ui.dart';

const wmsNewApiPhp = 'wms_new_api-php';
const wmsScmApiPhp = 'wms_scm_api-php';
const wmsBossApi = 'wms_boss_api';
const wmsUi = 'wms-ui';
const wmsBossUi = 'wms_boss_ui';

JenkinsProjectModel getInstance(BuildContext context, JenkinsModel jenkins, String name) {
  if ([wmsNewApiPhp, wmsScmApiPhp, wmsBossApi].contains(name)) {
    return JenkinsWmsBe(context, jenkins, name: name);
  }

  if ([wmsUi, wmsBossUi].contains(name)) {
    return JenkinsWmsUi(context, jenkins, name: name);
  }

  return JenkinsProjectModel(name: '');
}
