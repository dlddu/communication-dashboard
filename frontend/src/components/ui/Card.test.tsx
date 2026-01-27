import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { Card } from './Card';

describe('Card', () => {
  describe('rendering', () => {
    it('should render card with children text', () => {
      // Arrange & Act
      render(<Card>Card content</Card>);

      // Assert
      expect(screen.getByText('Card content')).toBeInTheDocument();
    });

    it('should apply default card class', () => {
      // Arrange & Act
      const { container } = render(<Card>Content</Card>);

      // Assert
      const card = container.firstChild as HTMLElement;
      expect(card).toHaveClass('card');
    });

    it('should apply custom className', () => {
      // Arrange & Act
      const { container } = render(<Card className="custom-card">Content</Card>);

      // Assert
      const card = container.firstChild as HTMLElement;
      expect(card).toHaveClass('card');
      expect(card).toHaveClass('custom-card');
    });

    it('should render with empty className by default', () => {
      // Arrange & Act
      const { container } = render(<Card>Content</Card>);

      // Assert
      const card = container.firstChild as HTMLElement;
      expect(card.className).toBe('card ');
    });
  });

  describe('children rendering', () => {
    it('should render simple text children', () => {
      // Arrange & Act
      render(<Card>Simple text</Card>);

      // Assert
      expect(screen.getByText('Simple text')).toBeInTheDocument();
    });

    it('should render complex nested children', () => {
      // Arrange & Act
      render(
        <Card>
          <h2>Title</h2>
          <p>Description</p>
          <button>Action</button>
        </Card>
      );

      // Assert
      expect(screen.getByText('Title')).toBeInTheDocument();
      expect(screen.getByText('Description')).toBeInTheDocument();
      expect(screen.getByRole('button', { name: 'Action' })).toBeInTheDocument();
    });

    it('should render multiple child elements', () => {
      // Arrange & Act
      render(
        <Card>
          <div>First</div>
          <div>Second</div>
          <div>Third</div>
        </Card>
      );

      // Assert
      expect(screen.getByText('First')).toBeInTheDocument();
      expect(screen.getByText('Second')).toBeInTheDocument();
      expect(screen.getByText('Third')).toBeInTheDocument();
    });

    it('should render React components as children', () => {
      // Arrange
      const ChildComponent = () => <span>Child Component</span>;

      // Act
      render(
        <Card>
          <ChildComponent />
        </Card>
      );

      // Assert
      expect(screen.getByText('Child Component')).toBeInTheDocument();
    });

    it('should render fragment children', () => {
      // Arrange & Act
      render(
        <Card>
          <>
            <div>Fragment child 1</div>
            <div>Fragment child 2</div>
          </>
        </Card>
      );

      // Assert
      expect(screen.getByText('Fragment child 1')).toBeInTheDocument();
      expect(screen.getByText('Fragment child 2')).toBeInTheDocument();
    });
  });

  describe('className handling', () => {
    it('should combine multiple custom classes', () => {
      // Arrange & Act
      const { container } = render(
        <Card className="shadow-lg rounded-lg p-4">Content</Card>
      );

      // Assert
      const card = container.firstChild as HTMLElement;
      expect(card).toHaveClass('card');
      expect(card).toHaveClass('shadow-lg');
      expect(card).toHaveClass('rounded-lg');
      expect(card).toHaveClass('p-4');
    });

    it('should handle empty className prop', () => {
      // Arrange & Act
      const { container } = render(<Card className="">Content</Card>);

      // Assert
      const card = container.firstChild as HTMLElement;
      expect(card).toHaveClass('card');
      expect(card.className).toBe('card ');
    });

    it('should not override base card class', () => {
      // Arrange & Act
      const { container } = render(<Card className="card">Content</Card>);

      // Assert
      const card = container.firstChild as HTMLElement;
      expect(card.className).toContain('card');
    });
  });

  describe('DOM structure', () => {
    it('should render as a div element', () => {
      // Arrange & Act
      const { container } = render(<Card>Content</Card>);

      // Assert
      const card = container.firstChild as HTMLElement;
      expect(card.tagName).toBe('DIV');
    });

    it('should be a single root element', () => {
      // Arrange & Act
      const { container } = render(<Card>Content</Card>);

      // Assert
      expect(container.children).toHaveLength(1);
    });
  });

  describe('edge cases', () => {
    it('should handle empty children', () => {
      // Arrange & Act
      const { container } = render(<Card>{''}</Card>);

      // Assert
      const card = container.firstChild as HTMLElement;
      expect(card).toBeInTheDocument();
      expect(card.textContent).toBe('');
    });

    it('should handle null children', () => {
      // Arrange & Act
      const { container } = render(<Card>{null}</Card>);

      // Assert
      const card = container.firstChild as HTMLElement;
      expect(card).toBeInTheDocument();
    });

    it('should handle undefined children', () => {
      // Arrange & Act
      const { container } = render(<Card>{undefined}</Card>);

      // Assert
      const card = container.firstChild as HTMLElement;
      expect(card).toBeInTheDocument();
    });

    it('should handle boolean children', () => {
      // Arrange
      const showVisible = true;
      const showHidden = false;

      // Act
      render(
        <Card>
          {showVisible && <span>Visible</span>}
          {showHidden && <span>Hidden</span>}
        </Card>
      );

      // Assert
      expect(screen.getByText('Visible')).toBeInTheDocument();
      expect(screen.queryByText('Hidden')).not.toBeInTheDocument();
    });

    it('should handle numeric children', () => {
      // Arrange & Act
      render(<Card>{42}</Card>);

      // Assert
      expect(screen.getByText('42')).toBeInTheDocument();
    });

    it('should handle array of children', () => {
      // Arrange
      const items = ['Item 1', 'Item 2', 'Item 3'];

      // Act
      render(
        <Card>
          {items.map((item, index) => (
            <div key={index}>{item}</div>
          ))}
        </Card>
      );

      // Assert
      expect(screen.getByText('Item 1')).toBeInTheDocument();
      expect(screen.getByText('Item 2')).toBeInTheDocument();
      expect(screen.getByText('Item 3')).toBeInTheDocument();
    });
  });

  describe('content layout', () => {
    it('should preserve child element structure', () => {
      // Arrange & Act
      render(
        <Card>
          <header>Header</header>
          <main>Main content</main>
          <footer>Footer</footer>
        </Card>
      );

      // Assert
      expect(screen.getByText('Header').tagName).toBe('HEADER');
      expect(screen.getByText('Main content').tagName).toBe('MAIN');
      expect(screen.getByText('Footer').tagName).toBe('FOOTER');
    });

    it('should render nested cards', () => {
      // Arrange & Act
      const { container } = render(
        <Card className="outer">
          <Card className="inner">Nested content</Card>
        </Card>
      );

      // Assert
      expect(screen.getByText('Nested content')).toBeInTheDocument();
      const cards = container.querySelectorAll('.card');
      expect(cards).toHaveLength(2);
    });
  });

  describe('accessibility', () => {
    it('should have accessible content', () => {
      // Arrange & Act
      render(
        <Card>
          <h2>Accessible Title</h2>
          <p>Accessible content</p>
        </Card>
      );

      // Assert
      expect(screen.getByText('Accessible Title')).toBeInTheDocument();
      expect(screen.getByText('Accessible content')).toBeInTheDocument();
    });

    it('should support ARIA attributes via className', () => {
      // Arrange & Act
      const { container } = render(
        <Card className="role-region">
          <div>Content with semantic meaning</div>
        </Card>
      );

      // Assert
      const card = container.firstChild as HTMLElement;
      expect(card).toHaveClass('role-region');
    });
  });
});
