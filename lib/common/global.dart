import 'package:flutter/cupertino.dart';
import 'package:jenkins_app/models/jenkins.dart';
import 'package:jenkins_app/models/jenkins_wms_be.dart';

const wmsNewApiPhp = 'wms_new_api-php';
const wmsScmApiPhp = 'wms_scm_api-php';
const wmsBossApi = 'wms_boss_api';

JenkinsProjectModel getInstance(BuildContext context, JenkinsModel jenkins, String name) {
  if ([wmsNewApiPhp, wmsScmApiPhp, wmsBossApi].contains(name)) {
    return JenkinsWmsBe(context, jenkins, name: name);
  }

  return JenkinsProjectModel(name: '');
}
