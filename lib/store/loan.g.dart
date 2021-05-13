// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loan.dart';

// **************************************************************************
// StoreGenerator
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, unnecessary_brace_in_string_interps, unnecessary_lambdas, prefer_expression_function_bodies, lines_longer_than_80_chars, avoid_as, avoid_annotating_with_dynamic

mixin _$LoanStore on _LoanStore, Store {
  final _$loanTypesAtom = Atom(name: '_LoanStore.loanTypes');

  @override
  List<LoanType> get loanTypes {
    _$loanTypesAtom.reportRead();
    return super.loanTypes;
  }

  @override
  set loanTypes(List<LoanType> value) {
    _$loanTypesAtom.reportWrite(value, super.loanTypes, () {
      super.loanTypes = value;
    });
  }

  final _$loansAtom = Atom(name: '_LoanStore.loans');

  @override
  Map<String, LoanData> get loans {
    _$loansAtom.reportRead();
    return super.loans;
  }

  @override
  set loans(Map<String, LoanData> value) {
    _$loansAtom.reportWrite(value, super.loans, () {
      super.loans = value;
    });
  }

  final _$loansLoadingAtom = Atom(name: '_LoanStore.loansLoading');

  @override
  bool get loansLoading {
    _$loansLoadingAtom.reportRead();
    return super.loansLoading;
  }

  @override
  set loansLoading(bool value) {
    _$loansLoadingAtom.reportWrite(value, super.loansLoading, () {
      super.loansLoading = value;
    });
  }

  final _$_LoanStoreActionController = ActionController(name: '_LoanStore');

  @override
  void setLoanTypes(List<LoanType> list) {
    final _$actionInfo = _$_LoanStoreActionController.startAction(
        name: '_LoanStore.setLoanTypes');
    try {
      return super.setLoanTypes(list);
    } finally {
      _$_LoanStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setAccountLoans(Map<String, LoanData> data) {
    final _$actionInfo = _$_LoanStoreActionController.startAction(
        name: '_LoanStore.setAccountLoans');
    try {
      return super.setAccountLoans(data);
    } finally {
      _$_LoanStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void setLoansLoading(bool loading) {
    final _$actionInfo = _$_LoanStoreActionController.startAction(
        name: '_LoanStore.setLoansLoading');
    try {
      return super.setLoansLoading(loading);
    } finally {
      _$_LoanStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  void loadCache(String pubKey) {
    final _$actionInfo =
        _$_LoanStoreActionController.startAction(name: '_LoanStore.loadCache');
    try {
      return super.loadCache(pubKey);
    } finally {
      _$_LoanStoreActionController.endAction(_$actionInfo);
    }
  }

  @override
  String toString() {
    return '''
loanTypes: ${loanTypes},
loans: ${loans},
loansLoading: ${loansLoading}
    ''';
  }
}
