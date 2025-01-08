import prompts from 'prompts';

import { logger } from '../../utils/logger';

export const promptDelegateeMenu = async () => {
  const { option } = await prompts({
    type: 'select',
    name: 'option',
    message: 'Select an action:',
    choices: [
      { title: 'Get Delegated PKPs', value: 'getDelegatedPkps' },
      { title: 'Get Registered Tools', value: 'getRegisteredTools' },
      { title: 'Get Tool Policy', value: 'getToolPolicy' },
      { title: 'Get Tool Via Intent', value: 'getToolViaIntent' },
      { title: 'Execute Tool', value: 'executeTool' },
    ],
  });

  if (!option) {
    logger.error('No option selected');
    process.exit(1);
  }

  return option;
};
