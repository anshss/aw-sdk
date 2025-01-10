import { promptSelectLitNetwork } from './prompts/select-lit-network';
import { promptSelectRole, Role } from './prompts/select-role';
import { Admin } from './roles/admin';
import { Delegatee } from './roles/delegatee';
import { logger } from './utils/logger';

export class AwCli {
  public async start() {
    const selectedLitNetwork = await promptSelectLitNetwork();
    const selectedRole = await promptSelectRole();
    logger.success(`Selected role: ${selectedRole}.`);

    let admin: Admin | null = null;
    let delegatee: Delegatee | null = null;
    switch (selectedRole) {
      case Role.Admin:
        try {
          admin = await Admin.create(selectedLitNetwork);
          await Admin.showManageOrMintMenu(admin);
        } finally {
          if (admin !== null) {
            admin.disconnect();
          }
        }
        break;
      case Role.Delegatee:
        try {
          delegatee = await Delegatee.create(selectedLitNetwork);
          await Delegatee.showMenu(delegatee);
        } finally {
          if (delegatee !== null) {
            delegatee.disconnect();
          }
        }
        break;
      default:
        logger.error('Invalid role selected.');
        process.exit(1);
    }
  }
}
