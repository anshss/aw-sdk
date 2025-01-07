/**
 * Represents the types of errors that can occur in the FSS (Function-as-a-Service) tool.
 * @enum {FssErrorType}
 * @description This enum is currently empty and can be extended with specific error types as needed.
 */
export enum FssErrorType {}

/**
 * Represents detailed information about an error.
 * @typedef {Object} ErrorDetails
 * @property {string} [name] - The name of the error.
 * @property {string} [message] - The error message.
 * @property {string} [stack] - The stack trace of the error.
 * @property {FssErrorType} [type] - The type of the error.
 * @property {unknown} [details] - Additional details about the error.
 * @property {unknown} [key: string] - Any additional custom properties.
 */
export type ErrorDetails = {
  name?: string;
  message?: string;
  stack?: string;
  type?: FssErrorType;
  details?: unknown;
  [key: string]: unknown;
};

/**
 * A custom error class for FSS (Function-as-a-Service) tools.
 * @class FssError
 * @extends Error
 * @description This class extends the native `Error` class and adds support for error types, detailed error information, and serialization.
 */
export class FssError extends Error {
  /**
   * A serialized version of the error details for better logging.
   * @type {string}
   */
  public readonly serializedDetails: string;

  /**
   * Creates a new FssError instance.
   * @param {FssErrorType} type - The type of the error.
   * @param {string} message - The error message.
   * @param {Record<string, ErrorDetails | unknown>} [details] - Additional details about the error.
   */
  constructor(
    public readonly type: FssErrorType,
    message: string,
    public readonly details?: Record<string, ErrorDetails | unknown>
  ) {
    super(message);
    this.name = 'FssError';

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
                ...(value instanceof FssError
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
   * Converts the error to a JSON-serializable object.
   * @returns {Object} - A JSON-serializable representation of the error.
   */
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
