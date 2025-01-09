import prompts from 'prompts';

/**
 * Enum representing the available roles.
 * - `Admin`: Can set policies and manage delegatees.
 * - `Delegatee`: Can execute tools within policy constraints.
 */
export enum Role {
  Admin = 'Admin',
  Delegatee = 'Delegatee',
}

/**
 * Prompts the user to select a role from a predefined list of options.
 * The user is presented with two choices: Admin and Delegatee.
 * If no role is selected, the function logs an error message and exits the process.
 *
 * @returns A promise that resolves to the selected `Role` value.
 * @throws If no role is selected, the function logs an error and exits the process with a status code of 1.
 */
export const promptSelectRole = async () => {
  // Prompt the user to select a role.
  const roleResponse = await prompts({
    type: 'select', // Use a select input type for the menu.
    name: 'role', // The name of the selected role.
    message: 'Select your role:', // The message displayed to the user.
    choices: [ // The list of available roles.
      {
        title: 'Admin - Can set policies and manage delegatees',
        value: 'Admin',
      },
      {
        title: 'Delegatee - Can execute tools within policy constraints',
        value: 'Delegatee',
      },
    ],
    initial: 0, // Set the initial selection to the first option (Admin).
  });

  // If no role is selected, log an error and exit the process.
  if (!roleResponse.role) {
    console.log('❌ Role selection is required to proceed.');
    process.exit(1);
  }

  // Return the selected role.
  return roleResponse.role as Role;
};
