export enum FssCliErrorType {
  ADMIN_PERMIT_TOOL_NO_UNPERMITTED_TOOLS = 'ADMIN_PERMIT_TOOL_NO_UNPERMITTED_TOOLS',
  ADMIN_PERMIT_TOOL_CANCELLED = 'ADMIN_PERMIT_TOOL_CANCELLED',
  ADMIN_REMOVE_TOOL_NO_PERMITTED_TOOLS = 'ADMIN_REMOVE_TOOL_NO_PERMITTED_TOOLS',
  ADMIN_REMOVE_TOOL_CANCELLED = 'ADMIN_REMOVE_TOOL_CANCELLED',
  ADMIN_GET_TOOL_POLICY_NO_TOOLS = 'ADMIN_GET_TOOL_POLICY_NO_TOOLS',
  ADMIN_GET_TOOL_POLICY_CANCELLED = 'ADMIN_GET_TOOL_POLICY_CANCELLED',
  ADMIN_SET_TOOL_POLICY_NO_TOOLS = 'ADMIN_SET_TOOL_POLICY_NO_TOOLS',
  ADMIN_SET_TOOL_POLICY_CANCELLED = 'ADMIN_SET_TOOL_POLICY_CANCELLED',
  ADMIN_SET_TOOL_POLICY_TOOL_NOT_IN_REGISTRY = 'ADMIN_SET_TOOL_POLICY_TOOL_NOT_IN_REGISTRY',
}

export type ErrorDetails = {
  name?: string;
  message?: string;
  stack?: string;
  type?: FssCliErrorType;
  details?: unknown;
  [key: string]: unknown;
};

export class FssCliError extends Error {
  public readonly serializedDetails: string;

  constructor(
    public readonly type: FssCliErrorType,
    message: string,
    public readonly details?: Record<string, ErrorDetails | unknown>
  ) {
    super(message);
    this.name = 'FssCliError';

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
                ...(value instanceof FssCliError
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
