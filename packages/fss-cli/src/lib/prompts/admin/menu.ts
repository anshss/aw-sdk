import prompts from 'prompts';

import { logger } from '../../utils/logger';

export const promptAdminMenu = async () => {
  const { option } = await prompts({
    type: 'select',
    name: 'option',
    message: 'Select an action:',
    choices: [
      { title: 'Permit Tool', value: 'permitTool' },
      { title: 'Remove Tool', value: 'removeTool' },
      { title: 'List Permitted Tools', value: 'getRegisteredTools' },
      { title: 'Get Tool Policy', value: 'getToolPolicy' },
      { title: 'Set Tool Policy', value: 'setToolPolicy' },
      { title: 'Remove Tool Policy', value: 'removeToolPolicy' },
      { title: 'List Delegatees', value: 'getDelegatees' },
      { title: 'Check if Address is Delegatee', value: 'isDelegatee' },
      { title: 'Add Delegatee', value: 'addDelegatee' },
      { title: 'Remove Delegatee', value: 'removeDelegatee' },
      { title: 'Batch Add Delegatees', value: 'batchAddDelegatees' },
      { title: 'Batch Remove Delegatees', value: 'batchRemoveDelegatees' },
    ],
  });

  if (!option) {
    logger.error('No option selected');
    process.exit(1);
  }

  return option;
};
