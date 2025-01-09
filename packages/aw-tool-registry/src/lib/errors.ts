/**
 * Enum representing the types of errors that can occur in the FssToolRegistry.
 * Each error type corresponds to a specific failure scenario.
 */
export enum FssToolRegistryErrorType {
  /** Indicates that the requested tool was not found in the registry. */
  TOOL_NOT_FOUND = 'TOOL_NOT_FOUND',

  /** Indicates that the IPFS CID (Content Identifier) for the tool was not found. */
  IPFS_CID_NOT_FOUND = 'IPFS_CID_NOT_FOUND',
}

/**
 * Type representing additional details about an error.
 * This can include nested errors, custom properties, or other metadata.
 */
export type ErrorDetails = {
  /** The name of the error. */
  name?: string;

  /** The error message. */
  message?: string;

  /** The stack trace of the error. */
  stack?: string;

  /** The type of the error, if it is an `FssToolRegistryError`. */
  type?: FssToolRegistryErrorType;

  /** Additional details about the error. */
  details?: unknown;

  /** Allows for additional custom properties. */
  [key: string]: unknown;
};

/**
 * Custom error class for the FssToolRegistry.
 * Extends the built-in `Error` class to include additional metadata such as error type and serialized details.
 */
export class FssToolRegistryError extends Error {
  /**
   * A serialized string representation of the error details.
   * This is useful for logging and debugging.
   */
  public readonly serializedDetails: string;

  /**
   * Creates an instance of `FssToolRegistryError`.
   *
   * @param type - The type of the error, as defined in `FssToolRegistryErrorType`.
   * @param message - A human-readable error message.
   * @param details - Optional additional details about the error, such as nested errors or custom properties.
   */
  constructor(
    public readonly type: FssToolRegistryErrorType,
    message: string,
    public readonly details?: Record<string, ErrorDetails | unknown>
  ) {
    super(message);
    this.name = 'RegistryError';

    // Serialize the details for better error logging
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
                ...(value instanceof FssToolRegistryError
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

  /**
   * Converts the error to a JSON-compatible object.
   * This is useful for serialization and logging.
   *
   * @returns An object containing the error's name, message, type, details, and stack trace.
   */
  toJSON() {
    return {
      name: this.name,
      message: this.message,
      type: this.type,
      details: this.serializedDetails
        ? JSON.parse(this.serializedDetails)
        : undefined,
      stack: this.stack,
    };
  }
}
