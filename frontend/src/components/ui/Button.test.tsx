import { describe, it, expect, vi } from 'vitest';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { Button } from './Button';

describe('Button', () => {
  describe('rendering', () => {
    it('should render button with children text', () => {
      // Arrange & Act
      render(<Button>Click me</Button>);

      // Assert
      expect(screen.getByRole('button', { name: 'Click me' })).toBeInTheDocument();
    });

    it('should render with primary variant by default', () => {
      // Arrange & Act
      render(<Button>Primary</Button>);

      // Assert
      const button = screen.getByRole('button');
      expect(button).toHaveClass('button-primary');
    });

    it('should render with secondary variant', () => {
      // Arrange & Act
      render(<Button variant="secondary">Secondary</Button>);

      // Assert
      const button = screen.getByRole('button');
      expect(button).toHaveClass('button-secondary');
    });

    it('should render with danger variant', () => {
      // Arrange & Act
      render(<Button variant="danger">Delete</Button>);

      // Assert
      const button = screen.getByRole('button');
      expect(button).toHaveClass('button-danger');
    });

    it('should apply custom className', () => {
      // Arrange & Act
      render(<Button className="custom-class">Custom</Button>);

      // Assert
      const button = screen.getByRole('button');
      expect(button).toHaveClass('custom-class');
      expect(button).toHaveClass('button');
    });

    it('should render with complex children', () => {
      // Arrange & Act
      render(
        <Button>
          <span>Icon</span>
          <span>Text</span>
        </Button>
      );

      // Assert
      expect(screen.getByText('Icon')).toBeInTheDocument();
      expect(screen.getByText('Text')).toBeInTheDocument();
    });
  });

  describe('loading state', () => {
    it('should show Loading text when loading is true', () => {
      // Arrange & Act
      render(<Button loading>Submit</Button>);

      // Assert
      expect(screen.getByText('Loading...')).toBeInTheDocument();
      expect(screen.queryByText('Submit')).not.toBeInTheDocument();
    });

    it('should disable button when loading', () => {
      // Arrange & Act
      render(<Button loading>Submit</Button>);

      // Assert
      expect(screen.getByRole('button')).toBeDisabled();
    });

    it('should not show loading text when loading is false', () => {
      // Arrange & Act
      render(<Button loading={false}>Submit</Button>);

      // Assert
      expect(screen.queryByText('Loading...')).not.toBeInTheDocument();
      expect(screen.getByText('Submit')).toBeInTheDocument();
    });
  });

  describe('disabled state', () => {
    it('should be disabled when disabled prop is true', () => {
      // Arrange & Act
      render(<Button disabled>Disabled</Button>);

      // Assert
      expect(screen.getByRole('button')).toBeDisabled();
    });

    it('should not be disabled by default', () => {
      // Arrange & Act
      render(<Button>Enabled</Button>);

      // Assert
      expect(screen.getByRole('button')).not.toBeDisabled();
    });

    it('should be disabled when both disabled and loading are true', () => {
      // Arrange & Act
      render(<Button disabled loading>Submit</Button>);

      // Assert
      expect(screen.getByRole('button')).toBeDisabled();
    });
  });

  describe('click interactions', () => {
    it('should call onClick handler when clicked', async () => {
      // Arrange
      const handleClick = vi.fn();
      const user = userEvent.setup();
      render(<Button onClick={handleClick}>Click me</Button>);

      // Act
      await user.click(screen.getByRole('button'));

      // Assert
      expect(handleClick).toHaveBeenCalledTimes(1);
    });

    it('should not call onClick when disabled', async () => {
      // Arrange
      const handleClick = vi.fn();
      const user = userEvent.setup();
      render(<Button onClick={handleClick} disabled>Click me</Button>);

      // Act
      await user.click(screen.getByRole('button'));

      // Assert
      expect(handleClick).not.toHaveBeenCalled();
    });

    it('should not call onClick when loading', async () => {
      // Arrange
      const handleClick = vi.fn();
      const user = userEvent.setup();
      render(<Button onClick={handleClick} loading>Click me</Button>);

      // Act
      await user.click(screen.getByRole('button'));

      // Assert
      expect(handleClick).not.toHaveBeenCalled();
    });

    it('should handle multiple clicks', async () => {
      // Arrange
      const handleClick = vi.fn();
      const user = userEvent.setup();
      render(<Button onClick={handleClick}>Click me</Button>);

      // Act
      await user.click(screen.getByRole('button'));
      await user.click(screen.getByRole('button'));
      await user.click(screen.getByRole('button'));

      // Assert
      expect(handleClick).toHaveBeenCalledTimes(3);
    });
  });

  describe('HTML button attributes', () => {
    it('should support type attribute', () => {
      // Arrange & Act
      render(<Button type="submit">Submit</Button>);

      // Assert
      expect(screen.getByRole('button')).toHaveAttribute('type', 'submit');
    });

    it('should support form attribute', () => {
      // Arrange & Act
      render(<Button form="my-form">Submit</Button>);

      // Assert
      expect(screen.getByRole('button')).toHaveAttribute('form', 'my-form');
    });

    it('should support aria-label', () => {
      // Arrange & Act
      render(<Button aria-label="Close dialog">X</Button>);

      // Assert
      expect(screen.getByRole('button')).toHaveAttribute('aria-label', 'Close dialog');
    });

    it('should support data attributes', () => {
      // Arrange & Act
      render(<Button data-testid="custom-button">Button</Button>);

      // Assert
      expect(screen.getByTestId('custom-button')).toBeInTheDocument();
    });
  });

  describe('edge cases', () => {
    it('should handle empty children', () => {
      // Arrange & Act
      render(<Button>{''}</Button>);

      // Assert
      const button = screen.getByRole('button');
      expect(button).toBeInTheDocument();
      expect(button.textContent).toBe('');
    });

    it('should handle null onClick', async () => {
      // Arrange
      const user = userEvent.setup();
      render(<Button>Click me</Button>);

      // Act & Assert - Should not throw
      await expect(user.click(screen.getByRole('button'))).resolves.not.toThrow();
    });

    it('should combine variant and custom classes', () => {
      // Arrange & Act
      render(<Button variant="danger" className="mt-4 px-6">Delete</Button>);

      // Assert
      const button = screen.getByRole('button');
      expect(button).toHaveClass('button');
      expect(button).toHaveClass('button-danger');
      expect(button).toHaveClass('mt-4');
      expect(button).toHaveClass('px-6');
    });
  });

  describe('accessibility', () => {
    it('should be keyboard accessible', async () => {
      // Arrange
      const handleClick = vi.fn();
      const user = userEvent.setup();
      render(<Button onClick={handleClick}>Click me</Button>);

      // Act
      const button = screen.getByRole('button');
      button.focus();
      await user.keyboard('{Enter}');

      // Assert
      expect(handleClick).toHaveBeenCalled();
    });

    it('should have button role', () => {
      // Arrange & Act
      render(<Button>Button</Button>);

      // Assert
      expect(screen.getByRole('button')).toBeInTheDocument();
    });

    it('should indicate disabled state to screen readers', () => {
      // Arrange & Act
      render(<Button disabled>Disabled</Button>);

      // Assert
      const button = screen.getByRole('button');
      expect(button).toHaveAttribute('disabled');
    });
  });
});
