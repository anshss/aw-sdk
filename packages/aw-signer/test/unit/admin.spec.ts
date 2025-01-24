import { LitNodeClientNodeJs } from '@lit-protocol/lit-node-client-nodejs';
import { LitContracts } from '@lit-protocol/contracts-sdk';
import { AUTH_METHOD_SCOPE } from '@lit-protocol/constants';
import { Admin } from '../../src/lib/admin';
import { AwSignerError, AwSignerErrorType } from '../../src/lib/errors';
import { LocalStorage } from '../../src/lib/utils/storage';

// Mock dependencies
jest.mock('@lit-protocol/lit-node-client-nodejs');
jest.mock('@lit-protocol/contracts-sdk');
jest.mock('../src/lib/utils/storage');

describe('Admin', () => {
  const mockPrivateKey =
    '0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef';
  const mockLitNetwork = 'datil';
  const mockPkpTokenId = '1234';
  const mockIpfsCid = 'QmTest';
  const mockNewOwner = '0x1234567890123456789012345678901234567890';

  let admin: Admin;
  let mockLitNodeClient: jest.Mocked<LitNodeClientNodeJs>;
  let mockLitContracts: jest.Mocked<LitContracts>;
  let mockStorage: jest.Mocked<LocalStorage>;

  beforeEach(async () => {
    // Reset mocks
    jest.clearAllMocks();

    // Setup mocks
    mockLitNodeClient = {
      connect: jest.fn().mockResolvedValue(undefined),
    } as any;

    const mockTransactionResponse = {
      wait: jest.fn().mockResolvedValue({ status: 1 }),
    };

    mockLitContracts = {
      connect: jest.fn().mockResolvedValue(undefined),
      pkpNftContract: {
        write: {
          'safeTransferFrom(address,address,uint256)': jest
            .fn()
            .mockResolvedValue(mockTransactionResponse),
        },
      },
      addPermittedAction: jest.fn().mockResolvedValue({ status: 1 }),
    } as any;

    mockStorage = {
      getItem: jest.fn(),
      setItem: jest.fn(),
    } as any;

    // Create Admin instance
    admin = await Admin.create(
      { type: 'eoa', privateKey: mockPrivateKey },
      { litNetwork: mockLitNetwork }
    );
  });

  describe('create', () => {
    it('should throw error if litNetwork is not provided', async () => {
      await expect(
        Admin.create({ type: 'eoa', privateKey: mockPrivateKey })
      ).rejects.toThrow(AwSignerError);
    });

    it('should throw error if private key is not provided and not in storage', async () => {
      mockStorage.getItem.mockReturnValue(null);
      await expect(
        Admin.create({ type: 'eoa' }, { litNetwork: mockLitNetwork })
      ).rejects.toThrow(AwSignerError);
    });

    it('should create Admin instance successfully with provided private key', async () => {
      const admin = await Admin.create(
        { type: 'eoa', privateKey: mockPrivateKey },
        { litNetwork: mockLitNetwork }
      );
      expect(admin).toBeInstanceOf(Admin);
    });

    it('should create Admin instance successfully with stored private key', async () => {
      mockStorage.getItem.mockReturnValue(mockPrivateKey);
      const admin = await Admin.create(
        { type: 'eoa' },
        { litNetwork: mockLitNetwork }
      );
      expect(admin).toBeInstanceOf(Admin);
    });
  });

  describe('PKP Management', () => {
    describe('getPkps', () => {
      it('should return PKPs from storage', async () => {
        const mockPkps = [{ info: { tokenId: mockPkpTokenId } }];
        jest.spyOn(admin as any, 'getPkps').mockResolvedValue(mockPkps);

        const pkps = await admin.getPkps();
        expect(pkps).toEqual(mockPkps);
      });
    });

    describe('getPkpByTokenId', () => {
      it('should return specific PKP if found', async () => {
        const mockPkp = { info: { tokenId: mockPkpTokenId } };
        jest.spyOn(admin as any, 'getPkps').mockResolvedValue([mockPkp]);

        const pkp = await admin.getPkpByTokenId(mockPkpTokenId);
        expect(pkp).toEqual(mockPkp);
      });

      it('should throw error if PKP not found', async () => {
        jest.spyOn(admin as any, 'getPkps').mockResolvedValue([]);

        await expect(admin.getPkpByTokenId(mockPkpTokenId)).rejects.toThrow(
          AwSignerError
        );
        await expect(
          admin.getPkpByTokenId(mockPkpTokenId)
        ).rejects.toMatchObject({
          type: AwSignerErrorType.ADMIN_PKP_NOT_FOUND,
        });
      });
    });

    describe('transferPkpOwnership', () => {
      it('should transfer PKP ownership successfully', async () => {
        const mockPkp = { info: { tokenId: mockPkpTokenId } };
        jest.spyOn(admin as any, 'getPkpByTokenId').mockResolvedValue(mockPkp);

        const receipt = await admin.transferPkpOwnership(
          mockPkpTokenId,
          mockNewOwner
        );
        expect(receipt.status).toBe(1);
      });

      it('should throw error if transfer fails', async () => {
        const mockPkp = { info: { tokenId: mockPkpTokenId } };
        jest.spyOn(admin as any, 'getPkpByTokenId').mockResolvedValue(mockPkp);

        const mockFailedTransaction = {
          wait: jest.fn().mockResolvedValue({ status: 0 }),
        };

        mockLitContracts.pkpNftContract.write[
          'safeTransferFrom(address,address,uint256)'
        ] = jest.fn().mockResolvedValue(mockFailedTransaction);

        await expect(
          admin.transferPkpOwnership(mockPkpTokenId, mockNewOwner)
        ).rejects.toThrow(AwSignerError);
        await expect(
          admin.transferPkpOwnership(mockPkpTokenId, mockNewOwner)
        ).rejects.toMatchObject({
          type: AwSignerErrorType.ADMIN_PKP_TRANSFER_FAILED,
        });
      });
    });
  });

  describe('Tool Management', () => {
    describe('permitTool', () => {
      it('should permit tool successfully', async () => {
        const mockPkp = { info: { tokenId: mockPkpTokenId } };
        jest.spyOn(admin as any, 'getPkpByTokenId').mockResolvedValue(mockPkp);

        const receipt = await admin.permitTool(mockPkpTokenId, mockIpfsCid, [
          AUTH_METHOD_SCOPE.SignAnything,
        ]);
        expect(receipt.status).toBe(1);
      });

      it('should use default signing scope if not provided', async () => {
        const mockPkp = { info: { tokenId: mockPkpTokenId } };
        jest.spyOn(admin as any, 'getPkpByTokenId').mockResolvedValue(mockPkp);

        const receipt = await admin.permitTool(mockPkpTokenId, mockIpfsCid);
        expect(receipt.status).toBe(1);
        expect(mockLitContracts.addPermittedAction).toHaveBeenCalledWith({
          ipfsId: mockIpfsCid,
          authMethodScopes: [AUTH_METHOD_SCOPE.SignAnything],
          pkpTokenId: mockPkpTokenId,
        });
      });
    });
  });
});
