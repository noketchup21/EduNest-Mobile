enum AuthFlowType {
  tutor,
  learner,
}

extension AuthFlowTypeX on AuthFlowType {
  bool get isTutor => this == AuthFlowType.tutor;

  String get title {
    switch (this) {
      case AuthFlowType.tutor:
        return 'Tutor';
      case AuthFlowType.learner:
        return 'Parent / Student';
    }
  }

  String get subtitle {
    switch (this) {
      case AuthFlowType.tutor:
        return 'Create courses, manage lessons, wallet, and payouts.';
      case AuthFlowType.learner:
        return 'Book tutors, pay by QR, view lessons, and chat.';
    }
  }

  List<String> get allowedRoles {
    switch (this) {
      case AuthFlowType.tutor:
        return ['Tutor', 'Admin'];
      case AuthFlowType.learner:
        return ['Parent', 'Student', 'Admin'];
    }
  }
}
