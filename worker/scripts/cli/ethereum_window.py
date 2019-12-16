from prompt_toolkit.layout.containers import VSplit, Window, HSplit, WindowAlign
from prompt_toolkit.layout.controls import BufferControl, FormattedTextControl
from prompt_toolkit.buffer import Buffer


def get_title_text():
    return 'Ethereum Status'


def balance(balance_txt: Buffer):
    return Window(BufferControl(buffer=balance_txt), align=WindowAlign.CENTER)


def node_address(eth_address_txt: Buffer):
    return Window(content=BufferControl(buffer=eth_address_txt), align=WindowAlign.CENTER)


def ethereum_window(balance_txt: Buffer, eth_address_txt: Buffer):
    body = HSplit([
        Window(
            height=1,
            content=FormattedTextControl(get_title_text),
            align=WindowAlign.CENTER,
        ),
        VSplit([
            HSplit([
                # Horizontal separator.
                Window(height=1, char="=", style="class:line"),
                # The 'body', like defined above.
                Window(height=1, content=FormattedTextControl("Node Ethereum Address"), align=WindowAlign.CENTER),
                node_address(eth_address_txt),

                Window(height=1, char="=", style="class:line"),
            ]),
            Window(width=2, char='||'),
            HSplit([
                # Horizontal separator.
                Window(height=1, char="=", style="class:line"),
                # The 'body', like defined above.
                Window(height=1, content=FormattedTextControl("Balance"), align=WindowAlign.CENTER),

                balance(balance_txt),
                Window(height=1, char="=", style="class:line"),
            ])
        ])

    ], height=5)

    return body

