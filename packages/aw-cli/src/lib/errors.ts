export enum AwCliErrorType {
  ADMIN_SELECT_PKP_CANCELLED = 'ADMIN_SELECT_PKP_CANCELLED',
  ADMIN_PERMIT_TOOL_NO_UNPERMITTED_TOOLS = 'ADMIN_PERMIT_TOOL_NO_UNPERMITTED_TOOLS',
  ADMIN_PERMIT_TOOL_CANCELLED = 'ADMIN_PERMIT_TOOL_CANCELLED',
  ADMIN_REMOVE_TOOL_NO_PERMITTED_TOOLS = 'ADMIN_REMOVE_TOOL_NO_PERMITTED_TOOLS',
  ADMIN_REMOVE_TOOL_CANCELLED = 'ADMIN_REMOVE_TOOL_CANCELLED',
  ADMIN_GET_TOOL_POLICY_NO_TOOLS = 'ADMIN_GET_TOOL_POLICY_NO_TOOLS',
  ADMIN_GET_TOOL_POLICY_CANCELLED = 'ADMIN_GET_TOOL_POLICY_CANCELLED',
  ADMIN_SET_TOOL_POLICY_NO_TOOLS = 'ADMIN_SET_TOOL_POLICY_NO_TOOLS',
  ADMIN_SET_TOOL_POLICY_CANCELLED = 'ADMIN_SET_TOOL_POLICY_CANCELLED',
  ADMIN_SET_TOOL_POLICY_TOOL_NOT_IN_REGISTRY = 'ADMIN_SET_TOOL_POLICY_TOOL_NOT_IN_REGISTRY',
  ADMIN_REMOVE_TOOL_POLICY_NO_TOOLS = 'ADMIN_REMOVE_TOOL_POLICY_NO_TOOLS',
  ADMIN_REMOVE_TOOL_POLICY_CANCELLED = 'ADMIN_REMOVE_TOOL_POLICY_CANCELLED',
  ADMIN_GET_DELEGATEE_ADDRESS_CANCELLED = 'ADMIN_GET_DELEGATEE_ADDRESS_CANCELLED',
  ADMIN_REMOVE_DELEGATEE_NO_DELEGATEES = 'ADMIN_REMOVE_DELEGATEE_NO_DELEGATEES',
  ADMIN_BATCH_ADD_DELEGATEE_CANCELLED = 'ADMIN_BATCH_ADD_DELEGATEE_CANCELLED',
  ADMIN_BATCH_REMOVE_DELEGATEE_CANCELLED = 'ADMIN_BATCH_REMOVE_DELEGATEE_CANCELLED',
  ADMIN_BATCH_REMOVE_DELEGATEE_NO_DELEGATEES = 'ADMIN_BATCH_REMOVE_DELEGATEE_NO_DELEGATEES',

  DELEGATEE_SELECT_PKP_CANCELLED = 'DELEGATEE_SELECT_PKP_CANCELLED',
  DELEGATEE_SELECT_TOOL_NO_TOOLS = 'DELEGATEE_SELECT_TOOL_NO_TOOLS',
  DELEGATEE_SELECT_TOOL_CANCELLED = 'DELEGATEE_SELECT_TOOL_CANCELLED',
  DELEGATEE_GET_TOOL_POLICY_NO_PKPS = 'DELEGATEE_GET_TOOL_POLICY_NO_PKPS',
  DELEGATEE_GET_TOOL_POLICY_NO_TOOLS_WITH_POLICY = 'DELEGATEE_GET_TOOL_POLICY_NO_TOOLS_WITH_POLICY',
  DELEGATEE_GET_TOOL_POLICY_TOOL_NOT_FOUND = 'DELEGATEE_GET_TOOL_POLICY_TOOL_NOT_FOUND',
  DELEGATEE_GET_TOOL_POLICY_NO_POLICY = 'DELEGATEE_GET_TOOL_POLICY_NO_POLICY',
  DELEGATEE_EXECUTE_TOOL_PARAMS_CANCELLED = 'DELEGATEE_EXECUTE_TOOL_PARAMS_CANCELLED',
  DELEGATEE_EXECUTE_TOOL_PARAMS_INVALID = 'DELEGATEE_EXECUTE_TOOL_PARAMS_INVALID',
  DELEGATEE_EXECUTE_TOOL_POLICY_VIOLATED = 'DELEGATEE_EXECUTE_TOOL_POLICY_VIOLATED',
  DELEGATEE_GET_TOOL_VIA_INTENT_NO_TOOLS = 'DELEGATEE_GET_TOOL_VIA_INTENT_NO_TOOLS',
  DELEGATEE_GET_TOOL_VIA_INTENT_NO_MATCH = 'DELEGATEE_GET_TOOL_VIA_INTENT_NO_MATCH',
  DELEGATEE_GET_TOOL_VIA_INTENT_CANCELLED = 'DELEGATEE_GET_TOOL_VIA_INTENT_CANCELLED',
  DELEGATEE_GET_TOOL_MATCHING_INTENT_CANCELLED = 'DELEGATEE_GET_TOOL_MATCHING_INTENT_CANCELLED',
  DELEGATEE_GET_INTENT_MATCHER_CANCELLED = 'DELEGATEE_GET_INTENT_MATCHER_CANCELLED',
}

export type ErrorDetails = {
  name?: string;
  message?: string;
  stack?: string;
  type?: AwCliErrorType;
  details?: unknown;
  [key: string]: unknown;
};

export class AwCliError extends Error {
  public readonly serializedDetails: string;

  constructor(
    public readonly type: AwCliErrorType,
    message: string,
    public readonly details?: Record<string, ErrorDetails | unknown>
  ) {
    super(message);
    this.name = 'AwCliError';

    // Store a serialized version of details for better error logging
    this.serializedDetails = details
      ? JSON.stringify(
          details,
          (key, value) => {
            if (value instanceof Error) {
              // Handle nested errors
              return {
                name: value.name,
                message: value.message,
                stack: value.stack,
                ...(value instanceof AwCliError
                  ? {
                      type: value.type,
                      details: value.serializedDetails
                        ? JSON.parse(value.serializedDetails)
                        : undefined,
                    }
                  : {}),
              };
            }
            return value;
          },
          2
        )
      : '';
  }

  // Override toJSON to provide better serialization
  toJSON() {
    return {
      name: this.name,
      type: this.type,
      message: this.message,
      details: this.serializedDetails
        ? JSON.parse(this.serializedDetails)
        : undefined,
      stack: this.stack,
    };
  }
}
