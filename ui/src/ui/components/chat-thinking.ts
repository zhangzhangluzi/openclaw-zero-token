import { LitElement, html, css, nothing } from "lit";
import { customElement, property, state } from "lit/decorators.js";
import { unsafeHTML } from "lit/directives/unsafe-html.js";
import { icons } from "../icons.ts";
import { toSanitizedMarkdownHtml } from "../markdown.ts";

@customElement("chat-thinking")
export class ChatThinking extends LitElement {
  @property({ type: String }) content = "";
  @property({ type: Number }) duration?: number;
  @state() private isExpanded = false;

  static styles = css`
    :host {
      display: block;
      margin-bottom: 8px;
    }

    .thinking-box {
      border: 1px solid var(--border-subtle, #e0e0e0);
      background: var(--bg-subtle, #f9f9f9);
      border-radius: 8px;
      overflow: hidden;
      transition: all 0.2s ease-in-out;
    }

    .thinking-header {
      padding: 8px 12px;
      display: flex;
      align-items: center;
      gap: 8px;
      cursor: pointer;
      user-select: none;
      font-size: 0.85rem;
      color: var(--text-muted, #666);
      background: var(--bg-subtle, #f9f9f9);
    }

    .thinking-header:hover {
      background: var(--bg-hover, #f0f0f0);
    }

    .thinking-icon {
      color: #2b6cb0; /* DeepSeek-like blue */
      display: flex;
      align-items: center;
      justify-content: center;
      width: 16px;
      height: 16px;
    }

    .thinking-icon svg {
      width: 100%;
      height: 100%;
    }

    .thinking-label {
      flex: 1;
      display: flex;
      align-items: center;
      gap: 4px;
    }

    .thinking-chevron {
      transition: transform 0.2s ease;
      display: flex;
      align-items: center;
    }

    .thinking-chevron.expanded {
      transform: rotate(180deg);
    }

    .thinking-content {
      padding: 0 12px 12px 12px;
      font-size: 0.9rem;
      line-height: 1.5;
      color: var(--text-main, #333);
      border-top: 1px solid transparent;
      max-height: 0;
      opacity: 0;
      overflow: hidden;
      transition: all 0.2s ease-in-out;
    }

    .thinking-content.expanded {
      max-height: 2000px; /* Large enough to accommodate most content */
      opacity: 1;
      padding-top: 8px;
      border-top-color: var(--border-subtle, #e0e0e0);
    }

    .thinking-content :first-child {
      margin-top: 0;
    }

    .thinking-content :last-child {
      margin-bottom: 0;
    }
  `;

  private toggle() {
    this.isExpanded = !this.isExpanded;
  }

  render() {
    if (!this.content.trim()) {
      return nothing;
    }

    const durationText = this.duration !== undefined ? ` (用时 ${this.duration} 秒)` : "";

    return html`
      <div class="thinking-box">
        <div class="thinking-header" @click=${this.toggle}>
          <span class="thinking-icon">${
            icons.brain ||
            icons.cpu ||
            html`
              <svg
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="2"
                stroke-linecap="round"
                stroke-linejoin="round"
              >
                <path
                  d="M9.5 2A1.5 1.5 0 0 0 8 3.5V6a2 2 0 0 1-2 2H3.5A1.5 1.5 0 0 0 2 9.5v5A1.5 1.5 0 0 0 3.5 16H6a2 2 0 0 1 2 2v2.5A1.5 1.5 0 0 0 9.5 22h5a1.5 1.5 0 0 0 1.5-1.5V18a2 2 0 0 1 2-2h2.5a1.5 1.5 0 0 0 1.5-1.5v-5A1.5 1.5 0 0 0 20.5 8H18a2 2 0 0 1-2-2V3.5A1.5 1.5 0 0 0 14.5 2h-5z"
                />
              </svg>
            `
          }</span>
          <span class="thinking-label">已思考${durationText}</span>
          <span class="thinking-chevron ${this.isExpanded ? "expanded" : ""}">
            ${
              icons.chevronDown ||
              html`
                <svg
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="currentColor"
                  stroke-width="2"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                >
                  <polyline points="6 9 12 15 18 9"></polyline>
                </svg>
              `
            }
          </span>
        </div>
        <div class="thinking-content ${this.isExpanded ? "expanded" : ""}">
          ${unsafeHTML(toSanitizedMarkdownHtml(this.content))}
        </div>
      </div>
    `;
  }
}

declare global {
  interface HTMLElementTagNameMap {
    "chat-thinking": ChatThinking;
  }
}
