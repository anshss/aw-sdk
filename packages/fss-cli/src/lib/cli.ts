import { promptSelectRole, Role } from './prompts/select-role';
import { Admin } from './roles/admin';
import { logger } from './utils/logger';

export class FssCli {
  public async start() {
    const selectedRole = await promptSelectRole();
    logger.success(`Selected role: ${selectedRole}.`);

    let admin: Admin | null = null;
    switch (selectedRole) {
      case Role.Admin:
        try {
          admin = await Admin.create();
          await Admin.showMenu();
        } finally {
          if (admin !== null) {
            admin.disconnect();
          }
        }
        break;
      case Role.Delegatee:
        break;
      default:
        logger.error('Invalid role selected.');
        process.exit(1);
    }
  }
}
