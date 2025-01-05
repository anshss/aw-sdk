import prompts from 'prompts';

export enum Role {
  Admin = 'Admin',
  Delegatee = 'Delegatee',
}

export const promptSelectRole = async () => {
  const roleResponse = await prompts({
    type: 'select',
    name: 'role',
    message: 'Select your role:',
    choices: [
      {
        title: 'Admin - Can set policies and manage delegatees',
        value: 'Admin',
      },
      {
        title: 'Delegatee - Can execute tools within policy constraints',
        value: 'Delegatee',
      },
    ],
    initial: 0,
  });

  if (!roleResponse.role) {
    console.log('❌ Role selection is required to proceed.');
    process.exit(1);
  }

  return roleResponse.role as Role;
};
