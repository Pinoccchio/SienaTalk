class UserAccount {
  final String firstName;
  final String middleName;
  final String lastName;
  final String id;
  final String password;

  UserAccount({
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.id,
    required this.password,
  });

  // Static method to create default student accounts
  static List<UserAccount> generateStudentAccounts() {
    return [
      UserAccount(
        firstName: 'Juan',
        middleName: 'Carlos',
        lastName: 'Dela Cruz',
        id: 'S12345',
        password: 'studentpassword123',
      ),
      UserAccount(
        firstName: 'Maria',
        middleName: 'Josefa',
        lastName: 'Reyes',
        id: 'S12346',
        password: 'studentpassword456',
      ),
      UserAccount(
        firstName: 'Jose',
        middleName: 'Luis',
        lastName: 'Santos',
        id: 'S12347',
        password: 'studentpassword789',
      ),
    ];
  }

  // Static method to create default admin accounts
  static List<UserAccount> generateAdminAccounts() {
    return [
      UserAccount(
        firstName: 'Ana',
        middleName: '',
        lastName: 'Mendoza',
        id: 'A10001',
        password: 'adminpassword123',
      ),
      UserAccount(
        firstName: 'Carlos',
        middleName: 'Antonio',
        lastName: 'Garcia',
        id: 'A10002',
        password: 'adminpassword456',
      ),
      UserAccount(
        firstName: 'Luz',
        middleName: 'Delia',
        lastName: 'Martinez',
        id: 'A10003',
        password: 'adminpassword789',
      ),
    ];
  }

  // Static method to create default employee accounts
  static List<UserAccount> generateEmployeeAccounts() {
    return [
      UserAccount(
        firstName: 'Eduardo',
        middleName: 'Luis',
        lastName: 'Santiago',
        id: 'E20001',
        password: 'employeepassword123',
      ),
      UserAccount(
        firstName: 'Teresa',
        middleName: 'Grace',
        lastName: 'Dizon',
        id: 'E20002',
        password: 'employeepassword456',
      ),
      UserAccount(
        firstName: 'Raul',
        middleName: 'Fernando',
        lastName: 'Ramirez',
        id: 'E20003',
        password: 'employeepassword789',
      ),
    ];
  }
}

