export interface ValidationResult {
  isValid: boolean;
  errors: string[];
}

export class InputValidator {
  static validatePresignedUrlRequest(body: any): ValidationResult {
    const errors: string[] = [];

    if (!body) {
      errors.push('Request body is required');
      return { isValid: false, errors };
    }

    // Validate fileName
    if (!body.fileName || typeof body.fileName !== 'string') {
      errors.push('fileName is required and must be a string');
    } else {
      // Sanitize filename
      const sanitizedFileName = body.fileName.replace(/[^a-zA-Z0-9.-]/g, '_');
      if (sanitizedFileName !== body.fileName) {
        errors.push('fileName contains invalid characters');
      }
      
      // Check file extension
      const allowedExtensions = ['.mp3', '.wav', '.m4a', '.aac', '.ogg', '.webm'];
      const hasValidExtension = allowedExtensions.some(ext => 
        body.fileName.toLowerCase().endsWith(ext)
      );
      if (!hasValidExtension) {
        errors.push('Invalid file extension. Allowed: ' + allowedExtensions.join(', '));
      }
    }

    // Validate fileSize
    if (body.fileSize === undefined || typeof body.fileSize !== 'number') {
      errors.push('fileSize is required and must be a number');
    } else {
      const maxSize = 50 * 1024 * 1024; // 50MB
      if (body.fileSize > maxSize) {
        errors.push(`File size exceeds maximum limit of ${maxSize} bytes`);
      }
      if (body.fileSize <= 0) {
        errors.push('File size must be greater than 0');
      }
    }

    // Validate contentType
    if (!body.contentType || typeof body.contentType !== 'string') {
      errors.push('contentType is required and must be a string');
    } else {
      const allowedContentTypes = [
        'audio/mpeg',
        'audio/mp3',
        'audio/wav',
        'audio/m4a',
        'audio/aac',
        'audio/ogg',
        'audio/webm',
      ];
      if (!allowedContentTypes.includes(body.contentType.toLowerCase())) {
        errors.push('Invalid content type. Allowed: ' + allowedContentTypes.join(', '));
      }
    }

    return {
      isValid: errors.length === 0,
      errors,
    };
  }

  static validateRecordId(recordId: string): ValidationResult {
    const errors: string[] = [];

    if (!recordId) {
      errors.push('Record ID is required');
    } else {
      // UUID v4 pattern
      const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
      if (!uuidPattern.test(recordId)) {
        errors.push('Invalid record ID format');
      }
    }

    return {
      isValid: errors.length === 0,
      errors,
    };
  }

  static sanitizeString(input: string, maxLength: number = 255): string {
    if (!input) return '';
    
    // Remove potentially dangerous characters
    let sanitized = input
      .replace(/[<>\"'&]/g, '') // Remove HTML/XML characters
      .replace(/[\x00-\x1f\x7f-\x9f]/g, '') // Remove control characters
      .trim();
    
    // Truncate if too long
    if (sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }
    
    return sanitized;
  }

  static validateEmail(email: string): boolean {
    const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailPattern.test(email);
  }
}