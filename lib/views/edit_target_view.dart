import 'package:flutter/material.dart';

import '../services/data/data_objects.dart';
import '../services/data/data_service.dart';
import '../widgets/loading_page.dart';

// import 'dart:developer' as devtools show log;

class EditTargetView extends StatefulWidget {
  final int? targetId;
  final bool? isEdit;
  
  const EditTargetView({Key? key, this.isEdit, this.targetId}) : super(key: key);

  @override
  State<EditTargetView> createState() => _EditTargetViewState();
}

class _EditTargetViewState extends State<EditTargetView> {
  final _dataService = DataService.current();
  final _formKey = GlobalKey<FormState>();
  final _typeNotifier = ValueNotifier<Type>(NutritionalValue);
  final _trackedIdNotifier = ValueNotifier<int>(-1);
  
  int? _orderId;
  
  late final bool isEdit;
  
  Target? _interimTarget;
  
  
  
  @override
  Widget build(BuildContext context) {
    return ;
  }
}