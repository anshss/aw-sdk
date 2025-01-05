import { promptSelectRole, Role } from './prompts/select-role';
import { Admin } from './roles/admin';
import { logger } from './utils/logger';

export class FssCli {
  public async start() {
    const selectedRole = await promptSelectRole();
    logger.success(`Selected role: ${selectedRole}.`);

    switch (selectedRole) {
      case Role.Admin:
        await Admin.create();
        break;
      case Role.Delegatee:
        break;
      default:
        logger.error('Invalid role selected.');
        process.exit(1);
    }
  }
}
