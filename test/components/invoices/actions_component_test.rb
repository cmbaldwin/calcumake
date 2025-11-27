# frozen_string_literal: true

require "test_helper"

module Invoices
  class ActionsComponentTest < ViewComponent::TestCase
    # Basic Rendering Tests

    test "renders with required attributes" do
      invoice = invoices(:one)
      print_pricing = invoice.print_pricing

      render_inline(ActionsComponent.new(
        invoice: invoice,
        print_pricing: print_pricing
      ))

      assert_selector "a.btn.btn-primary", text: /Edit/i
    end

    # Status Actions Tests

    test "shows status actions for draft invoice" do
      invoice = invoices(:one)
      invoice.stub :status, "draft" do
        print_pricing = invoice.print_pricing

        render_inline(ActionsComponent.new(
          invoice: invoice,
          print_pricing: print_pricing
        ))

        assert_selector "form button", text: "Mark as Sent"
        assert_selector "form button", text: "Mark as Paid"
      end
    end

    test "shows status actions for sent invoice" do
      invoice = invoices(:one)
      invoice.stub :status, "sent" do
        print_pricing = invoice.print_pricing

        render_inline(ActionsComponent.new(
          invoice: invoice,
          print_pricing: print_pricing
        ))

        assert_selector "form button", text: "Mark as Sent"
        assert_selector "form button", text: "Mark as Paid"
      end
    end

    test "hides status actions for paid invoice" do
      invoice = invoices(:one)
      invoice.stub :status, "paid" do
        print_pricing = invoice.print_pricing

        render_inline(ActionsComponent.new(
          invoice: invoice,
          print_pricing: print_pricing
        ))

        refute_selector "form button", text: "Mark as Sent"
        refute_selector "form button", text: "Mark as Paid"
      end
    end

    test "hides status actions when show_status_actions is false" do
      invoice = invoices(:one)
      invoice.stub :status, "draft" do
        print_pricing = invoice.print_pricing

        render_inline(ActionsComponent.new(
          invoice: invoice,
          print_pricing: print_pricing,
          show_status_actions: false
        ))

        refute_selector "form button", text: "Mark as Sent"
        refute_selector "form button", text: "Mark as Paid"
      end
    end

    # Button Disabled States Tests

    test "disables mark as sent when invoice is sent" do
      invoice = invoices(:one)
      invoice.stub :status, "sent" do
        print_pricing = invoice.print_pricing

        render_inline(ActionsComponent.new(
          invoice: invoice,
          print_pricing: print_pricing
        ))

        assert_selector "form button[disabled]", text: "Mark as Sent"
      end
    end

    test "enables mark as sent when invoice is draft" do
      invoice = invoices(:one)
      invoice.stub :status, "draft" do
        print_pricing = invoice.print_pricing

        render_inline(ActionsComponent.new(
          invoice: invoice,
          print_pricing: print_pricing
        ))

        refute_selector "form button[disabled]", text: "Mark as Sent"
      end
    end

    test "disables mark as paid when invoice is draft" do
      invoice = invoices(:one)
      invoice.stub :status, "draft" do
        print_pricing = invoice.print_pricing

        render_inline(ActionsComponent.new(
          invoice: invoice,
          print_pricing: print_pricing
        ))

        assert_selector "form button[disabled]", text: "Mark as Paid"
      end
    end

    test "enables mark as paid when invoice is sent" do
      invoice = invoices(:one)
      invoice.stub :status, "sent" do
        print_pricing = invoice.print_pricing

        render_inline(ActionsComponent.new(
          invoice: invoice,
          print_pricing: print_pricing
        ))

        refute_selector "form button[disabled]", text: "Mark as Paid"
      end
    end

    # Individual Button Toggle Tests

    test "shows edit button by default" do
      invoice = invoices(:one)
      print_pricing = invoice.print_pricing

      render_inline(ActionsComponent.new(
        invoice: invoice,
        print_pricing: print_pricing
      ))

      assert_selector "a.btn.btn-primary", text: /Edit/i
    end

    test "hides edit button when show_edit is false" do
      invoice = invoices(:one)
      print_pricing = invoice.print_pricing

      render_inline(ActionsComponent.new(
        invoice: invoice,
        print_pricing: print_pricing,
        show_edit: false
      ))

      refute_selector "a.btn.btn-primary", text: /Edit/i
    end

    test "shows PDF button by default" do
      invoice = invoices(:one)
      print_pricing = invoice.print_pricing

      render_inline(ActionsComponent.new(
        invoice: invoice,
        print_pricing: print_pricing
      ))

      assert_selector "button[data-action='click->pdf-generator#generatePDF']"
      assert_selector "i.bi-file-pdf"
    end

    test "hides PDF button when show_pdf is false" do
      invoice = invoices(:one)
      print_pricing = invoice.print_pricing

      render_inline(ActionsComponent.new(
        invoice: invoice,
        print_pricing: print_pricing,
        show_pdf: false
      ))

      refute_selector "button[data-action='click->pdf-generator#generatePDF']"
    end

    test "shows print button by default" do
      invoice = invoices(:one)
      print_pricing = invoice.print_pricing

      render_inline(ActionsComponent.new(
        invoice: invoice,
        print_pricing: print_pricing
      ))

      assert_selector "button[onclick='window.print()']"
      assert_selector "i.bi-printer"
    end

    test "hides print button when show_print is false" do
      invoice = invoices(:one)
      print_pricing = invoice.print_pricing

      render_inline(ActionsComponent.new(
        invoice: invoice,
        print_pricing: print_pricing,
        show_print: false
      ))

      refute_selector "button[onclick='window.print()']"
    end

    # Wrapper Class Tests

    test "renders without wrapper by default" do
      invoice = invoices(:one)
      print_pricing = invoice.print_pricing

      render_inline(ActionsComponent.new(
        invoice: invoice,
        print_pricing: print_pricing
      ))

      # Should have buttons but no wrapper div
      assert_selector "a.btn"
      # Check that wrapper class is not present
      refute_selector "div.custom-wrapper"
    end

    test "applies wrapper class when provided" do
      invoice = invoices(:one)
      print_pricing = invoice.print_pricing

      render_inline(ActionsComponent.new(
        invoice: invoice,
        print_pricing: print_pricing,
        wrapper_class: "d-flex gap-2 justify-content-end"
      ))

      assert_selector "div.d-flex.gap-2.justify-content-end"
    end

    # URL Generation Tests

    test "generates correct mark as sent URL" do
      invoice = invoices(:one)
      invoice.stub :status, "draft" do
        print_pricing = invoice.print_pricing

        render_inline(ActionsComponent.new(
          invoice: invoice,
          print_pricing: print_pricing
        ))

        assert_selector "form[action*='mark_as_sent']"
      end
    end

    test "generates correct mark as paid URL" do
      invoice = invoices(:one)
      invoice.stub :status, "sent" do
        print_pricing = invoice.print_pricing

        render_inline(ActionsComponent.new(
          invoice: invoice,
          print_pricing: print_pricing
        ))

        assert_selector "form[action*='mark_as_paid']"
      end
    end

    test "generates correct edit URL" do
      invoice = invoices(:one)
      print_pricing = invoice.print_pricing

      render_inline(ActionsComponent.new(
        invoice: invoice,
        print_pricing: print_pricing
      ))

      assert_selector "a[href*='edit']"
    end

    # Translation Tests

    test "uses translations for button labels" do
      invoice = invoices(:one)
      invoice.stub :status, "draft" do
        print_pricing = invoice.print_pricing

        I18n.with_locale(:en) do
          render_inline(ActionsComponent.new(
            invoice: invoice,
            print_pricing: print_pricing
          ))

          assert_selector "form button", text: "Mark as Sent"
          assert_selector "form button", text: "Mark as Paid"
          assert_selector "a", text: /Edit/i
        end
      end
    end

    # Edge Cases

    test "handles all buttons hidden" do
      invoice = invoices(:one)
      invoice.stub :status, "paid" do
        print_pricing = invoice.print_pricing

        render_inline(ActionsComponent.new(
          invoice: invoice,
          print_pricing: print_pricing,
          show_edit: false,
          show_pdf: false,
          show_print: false
        ))

        # No buttons should be visible
        refute_selector "button"
        refute_selector "form button"
        refute_selector "a.btn"
      end
    end

    test "handles minimal configuration with only edit button" do
      invoice = invoices(:one)
      invoice.stub :status, "paid" do
        print_pricing = invoice.print_pricing

        render_inline(ActionsComponent.new(
          invoice: invoice,
          print_pricing: print_pricing,
          show_pdf: false,
          show_print: false
        ))

        assert_selector "a.btn.btn-primary", text: /Edit/i
        refute_selector "button"
      end
    end
  end
end
