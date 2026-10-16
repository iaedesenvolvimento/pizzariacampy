import 'package:flutter/material.dart';

import 'admin_finance_controller.dart';
import 'admin_design_system.dart';

class AdminFinancePage extends StatefulWidget {
  const AdminFinancePage({super.key});

  @override
  State<AdminFinancePage> createState() => _AdminFinancePageState();
}

class _AdminFinancePageState extends State<AdminFinancePage> {
  late final AdminFinanceController _controller;
  FinanceSection _section = FinanceSection.summary;

  @override
  void initState() {
    super.initState();
    _controller = AdminFinanceController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => AdminScaffold(
        title: 'Financeiro',
        subtitle:
            'Acompanhe vendas, pagamentos e indicadores financeiros da operação.',
        activeDestination: AdminDestinationId.finance,
        actions: [
          IconButton(
            tooltip: 'Atualizar financeiro',
            onPressed: _controller.loading ? null : _controller.load,
            icon: const Icon(Icons.refresh),
          ),
        ],
        body: _controller.loading && _controller.summary == null
            ? const AdminLoadingState(label: 'Carregando financeiro')
            : _controller.error != null && _controller.summary == null
                ? AdminErrorState(
                    message: _controller.error!, onRetry: _controller.load)
                : _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final summary = _controller.summary!;
    return RefreshIndicator(
      onRefresh: _controller.load,
      child: ListView(
        padding: const EdgeInsets.all(AdminSpacing.lg),
        children: [
          AdminPageHeader(
            title: 'Resumo financeiro',
            subtitle: 'Período: ${_controller.period.label}',
          ),
          AdminFilterBar(
            children: [
              for (final period in FinancePeriod.values)
                ChoiceChip(
                  label: Text(period.label),
                  selected: _controller.period == period,
                  onSelected: (_) => _selectPeriod(period),
                ),
            ],
          ),
          const SizedBox(height: AdminSpacing.md),
          AdminFilterBar(
            children: [
              for (final section in FinanceSection.values)
                ChoiceChip(
                  label: Text(_sectionLabel(section)),
                  selected: _section == section,
                  onSelected: (_) => _selectSection(section),
                ),
            ],
          ),
          if (_controller.error != null) ...[
            const SizedBox(height: AdminSpacing.md),
            Text(_controller.error!,
                style: const TextStyle(color: AdminColors.danger)),
          ],
          const SizedBox(height: AdminSpacing.lg),
          switch (_section) {
            FinanceSection.summary => _summaryContent(context, summary),
            FinanceSection.sales => _salesContent(context),
            FinanceSection.pix => _pixContent(context),
            FinanceSection.cancellations => _cancellationsContent(context),
          },
        ],
      ),
    );
  }

  String _sectionLabel(FinanceSection section) => switch (section) {
        FinanceSection.summary => 'Resumo',
        FinanceSection.sales => 'Vendas',
        FinanceSection.pix => 'PIX pendentes',
        FinanceSection.cancellations => 'Cancelamentos',
      };

  Future<void> _selectSection(FinanceSection section) async {
    setState(() => _section = section);
    if (section == FinanceSection.pix && _controller.pixPending.isEmpty) {
      await _controller.loadPixPending();
    } else if (section == FinanceSection.cancellations &&
        _controller.cancellations.isEmpty) {
      await _controller.loadCancellations();
    }
  }

  Widget _summaryContent(BuildContext context, FinanceSummary summary) {
    return Column(
      children: [
        _metricGrid(context, summary),
        const SizedBox(height: AdminSpacing.lg),
        _secondaryGrid(context, summary),
        const SizedBox(height: AdminSpacing.lg),
        _methodsAndAttention(context, summary),
        const SizedBox(height: AdminSpacing.lg),
        _recentSales(context),
      ],
    );
  }

  Widget _salesContent(BuildContext context) {
    return Column(
      children: [
        AdminSectionCard(
          title: 'Filtros de vendas',
          child: AdminFilterBar(
            children: [
              _filterChip(
                  'Todos os pagamentos',
                  _controller.salesPaymentStatus == null,
                  () => _controller.setSalesFilters(
                      method: _controller.salesPaymentMethod,
                      orderStatus: _controller.salesOrderStatus)),
              _filterChip(
                  'PIX',
                  _controller.salesPaymentMethod == 'PIX',
                  () => _controller.setSalesFilters(
                      method: _controller.salesPaymentMethod == 'PIX'
                          ? null
                          : 'PIX',
                      paymentStatus: _controller.salesPaymentStatus,
                      orderStatus: _controller.salesOrderStatus)),
              _filterChip(
                  'Em análise',
                  _controller.salesPaymentStatus == 'UNDER_REVIEW',
                  () => _controller.setSalesFilters(
                      method: _controller.salesPaymentMethod,
                      paymentStatus:
                          _controller.salesPaymentStatus == 'UNDER_REVIEW'
                              ? null
                              : 'UNDER_REVIEW',
                      orderStatus: _controller.salesOrderStatus)),
              _filterChip(
                  'Confirmado',
                  _controller.salesPaymentStatus == 'CONFIRMED',
                  () => _controller.setSalesFilters(
                      method: _controller.salesPaymentMethod,
                      paymentStatus:
                          _controller.salesPaymentStatus == 'CONFIRMED'
                              ? null
                              : 'CONFIRMED',
                      orderStatus: _controller.salesOrderStatus)),
            ],
          ),
        ),
        const SizedBox(height: AdminSpacing.md),
        if (_controller.sectionError != null)
          AdminErrorState(
              message: _controller.sectionError!,
              onRetry: _controller.loadSales)
        else if (_controller.sectionLoading)
          const AdminLoadingState(label: 'Carregando vendas')
        else if (_controller.sales.isEmpty)
          const AdminEmptyState(
              message: 'Nenhuma venda encontrada para os filtros selecionados.')
        else
          AdminSectionCard(
            title: 'Vendas (${_controller.salesTotal})',
            child: Column(
              children: [
                for (final sale in _controller.sales)
                  _saleDetailCard(context, sale),
                _paginationControls(),
              ],
            ),
          ),
      ],
    );
  }

  Widget _filterChip(String label, bool selected, VoidCallback onPressed) {
    return FilterChip(
        label: Text(label), selected: selected, onSelected: (_) => onPressed());
  }

  Widget _saleDetailCard(BuildContext context, FinanceSale sale) {
    final visual = paymentStatusVisual(sale.paymentStatus);
    return Card(
      margin: const EdgeInsets.only(bottom: AdminSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AdminSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                  child: Text(sale.orderNumber,
                      style: Theme.of(context).textTheme.titleMedium)),
              Text(formatFinanceMoney(sale.totalAmount),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: AdminSpacing.xs),
            Text(formatFinanceDate(sale.createdAt)),
            const Divider(),
            Wrap(
              spacing: AdminSpacing.lg,
              runSpacing: AdminSpacing.sm,
              children: [
                _valueLine('Subtotal', formatFinanceMoney(sale.subtotal)),
                _valueLine('Desconto', formatFinanceMoney(sale.discountAmount)),
                _valueLine(
                    'Taxa de entrega', formatFinanceMoney(sale.deliveryFee)),
              ],
            ),
            const SizedBox(height: AdminSpacing.sm),
            Wrap(
                spacing: AdminSpacing.sm,
                runSpacing: AdminSpacing.sm,
                children: [
                  Chip(
                      avatar:
                          Icon(visual.icon, size: 16, color: visual.foreground),
                      label: Text(paymentStatusLabel(sale.paymentStatus))),
                  Chip(label: Text(paymentMethodLabel(sale.paymentMethod))),
                  Chip(
                      label:
                          Text(AdminStatuses.forValue(sale.orderStatus).label)),
                ]),
            Semantics(
              label: 'Valor da venda, não necessariamente pagamento recebido',
              child: Text(
                  'Total do pedido: ${formatFinanceMoney(sale.totalAmount)}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paginationControls() {
    final previous = _controller.salesOffset > 0;
    final next = _controller.salesOffset + _controller.sales.length <
        _controller.salesTotal;
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      TextButton.icon(
        onPressed: previous
            ? () {
                _controller.salesOffset =
                    (_controller.salesOffset - _controller.salesLimit)
                        .clamp(0, 999999);
                _controller.loadSales();
              }
            : null,
        icon: const Icon(Icons.chevron_left),
        label: const Text('Anterior'),
      ),
      TextButton.icon(
        onPressed: next
            ? () {
                _controller.salesOffset += _controller.salesLimit;
                _controller.loadSales();
              }
            : null,
        icon: const Icon(Icons.chevron_right),
        label: const Text('Próxima'),
      ),
    ]);
  }

  Widget _pixContent(BuildContext context) {
    if (_controller.sectionLoading) {
      return const AdminLoadingState(label: 'Carregando pagamentos PIX');
    }
    if (_controller.sectionError != null) {
      return AdminErrorState(
          message: _controller.sectionError!,
          onRetry: _controller.loadPixPending);
    }
    if (_controller.pixPending.isEmpty) {
      return const AdminEmptyState(
          message: 'Nenhum pagamento PIX pendente neste período.');
    }
    return Column(children: [
      for (final item in _controller.pixPending) _pixCard(context, item),
    ]);
  }

  Widget _pixCard(BuildContext context, FinancePixPending item) {
    final underReview = item.paymentStatus == 'UNDER_REVIEW';
    return AdminSectionCard(
      title: item.orderNumber,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            '${formatFinanceDate(item.createdAt)} · ${formatFinanceMoney(item.totalAmount)}'),
        const SizedBox(height: AdminSpacing.sm),
        Text(
            underReview
                ? 'ATENÇÃO · Aguardando análise administrativa'
                : 'Aguardando comprovante do cliente',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color:
                    underReview ? AdminColors.warning : AdminColors.neutral)),
        if (item.proofUrl != null && underReview) ...[
          const SizedBox(height: AdminSpacing.sm),
          OutlinedButton.icon(
              onPressed: () => _showProof(context, item.proofUrl!),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Visualizar comprovante')),
        ],
        if (underReview)
          TextButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed('/admin/orders'),
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text('Revisar em Pedidos')),
      ]),
    );
  }

  Future<void> _showProof(BuildContext context, String proofUrl) async {
    await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text('Comprovante PIX'),
              content: SelectableText(proofUrl),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fechar'))
              ],
            ));
  }

  Widget _cancellationsContent(BuildContext context) {
    if (_controller.sectionLoading) {
      return const AdminLoadingState(label: 'Carregando cancelamentos');
    }
    if (_controller.sectionError != null) {
      return AdminErrorState(
          message: _controller.sectionError!,
          onRetry: _controller.loadCancellations);
    }
    if (_controller.cancellations.isEmpty) {
      return const AdminEmptyState(
          message: 'Nenhum cancelamento encontrado neste período.');
    }
    return Column(children: [
      for (final item in _controller.cancellations)
        _cancellationCard(context, item),
    ]);
  }

  Widget _cancellationCard(BuildContext context, FinanceCancellation item) {
    return AdminSectionCard(
      title: item.orderNumber,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
            '${formatFinanceDate(item.createdAt)} · ${formatFinanceMoney(item.totalAmount)}'),
        Text(
            '${paymentMethodLabel(item.paymentMethod)} · ${paymentStatusLabel(item.paymentStatus)}'),
        if (item.reason != null) Text('Motivo: ${item.reason}'),
        if (item.paymentConfirmed) ...[
          const SizedBox(height: AdminSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AdminSpacing.md),
            color: AdminColors.warningSurface,
            child: const Text(
                'ATENÇÃO\nPagamento confirmado em pedido cancelado. O sistema ainda não possui fluxo de estorno/reembolso.'),
          ),
        ],
      ]),
    );
  }

  Widget _metricGrid(BuildContext context, FinanceSummary summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 560
                ? 2
                : 1;
        return GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: AdminSpacing.md,
          mainAxisSpacing: AdminSpacing.md,
          childAspectRatio: columns == 1 ? 2.2 : 1.55,
          children: [
            AdminMetricCard(
              label: 'Vendas operacionais',
              value: formatFinanceMoney(summary.grossSales),
              icon: Icons.trending_up,
              color: AdminColors.success,
            ),
            AdminMetricCard(
              label: 'Pedidos',
              value: summary.ordersCount.toString(),
              icon: Icons.receipt_long_outlined,
              color: AdminColors.info,
            ),
            AdminMetricCard(
              label: 'Ticket médio',
              value: formatFinanceMoney(summary.averageTicket),
              icon: Icons.shopping_basket_outlined,
            ),
            AdminMetricCard(
              label: 'PIX pendente',
              value: summary.pixPendingCount.toString(),
              icon: Icons.pix_outlined,
              color: AdminColors.warning,
            ),
          ],
        );
      },
    );
  }

  Widget _secondaryGrid(BuildContext context, FinanceSummary summary) {
    return AdminSectionCard(
      title: 'Indicadores complementares',
      child: Wrap(
        spacing: AdminSpacing.xl,
        runSpacing: AdminSpacing.md,
        children: [
          _valueLine('Descontos', formatFinanceMoney(summary.discountsTotal)),
          _valueLine('Taxas de entrega',
              formatFinanceMoney(summary.deliveryFeesTotal)),
          _valueLine(
              'Pedidos cancelados', summary.cancelledOrdersCount.toString()),
          _valueLine('Valor de pedidos cancelados',
              formatFinanceMoney(summary.cancelledAmount)),
        ],
      ),
    );
  }

  Widget _methodsAndAttention(BuildContext context, FinanceSummary summary) {
    final methods = AdminSectionCard(
      title: 'Vendas por método de pagamento',
      child: summary.paymentMethods.isEmpty
          ? const AdminEmptyState(
              message: 'Nenhuma venda encontrada neste período.')
          : Column(
              children: [
                for (final method in summary.paymentMethods)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.payments_outlined),
                    title: Text(paymentMethodLabel(method.method)),
                    subtitle: Text('${method.orderCount} pedido(s)'),
                    trailing: Text(formatFinanceMoney(method.amount)),
                  ),
              ],
            ),
    );
    final attention = AdminSectionCard(
      title: 'Atenção necessária',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.pending_actions_outlined),
            title: const Text('PIX aguardando análise'),
            subtitle: Text(
                '${summary.pixAwaitingReviewCount} pedido(s) aguardando revisão'),
            trailing: TextButton(
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed('/admin/orders'),
              child: const Text('Acessar pendências'),
            ),
          ),
          Text('${summary.pixAwaitingProofCount} aguardando comprovante',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) => constraints.maxWidth >= 760
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: methods),
                const SizedBox(width: AdminSpacing.md),
                Expanded(child: attention),
              ],
            )
          : Column(
              children: [
                methods,
                const SizedBox(height: AdminSpacing.md),
                attention
              ],
            ),
    );
  }

  Widget _recentSales(BuildContext context) {
    return AdminSectionCard(
      title: 'Vendas recentes',
      child: _controller.sales.isEmpty
          ? const AdminEmptyState(
              message: 'Nenhuma venda encontrada neste período.')
          : Column(
              children: [
                for (final sale in _controller.sales) _saleTile(context, sale),
              ],
            ),
    );
  }

  Widget _saleTile(BuildContext context, FinanceSale sale) {
    final visual = paymentStatusVisual(sale.paymentStatus);
    return Card(
      margin: const EdgeInsets.only(bottom: AdminSpacing.sm),
      child: ListTile(
        leading: Icon(Icons.receipt_long_outlined, color: visual.foreground),
        title: Text(sale.orderNumber),
        subtitle: Text(
            '${formatFinanceDate(sale.createdAt)} · ${paymentMethodLabel(sale.paymentMethod)}\n'
            '${AdminStatuses.forValue(sale.orderStatus).label} · ${paymentStatusLabel(sale.paymentStatus)}'),
        isThreeLine: true,
        trailing: Text(formatFinanceMoney(sale.totalAmount)),
      ),
    );
  }

  Widget _valueLine(String label, String value) {
    return SizedBox(
      width: 230,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700))
        ],
      ),
    );
  }

  Future<void> _selectPeriod(FinancePeriod period) async {
    if (period != FinancePeriod.custom) {
      await _controller.setPeriod(period);
      await _reloadSelectedSection();
      return;
    }
    final now = DateTime.now();
    final pickedStart = await showDatePicker(
      context: context,
      initialDate: _controller.customStart ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'Data inicial',
    );
    if (!mounted || pickedStart == null) return;
    final pickedEnd = await showDatePicker(
      context: context,
      initialDate: _controller.customEnd ?? pickedStart,
      firstDate: pickedStart,
      lastDate: now,
      helpText: 'Data final',
    );
    if (!mounted || pickedEnd == null) return;
    await _controller.setCustomPeriod(pickedStart, pickedEnd);
    await _reloadSelectedSection();
  }

  Future<void> _reloadSelectedSection() async {
    switch (_section) {
      case FinanceSection.summary:
        return;
      case FinanceSection.sales:
        await _controller.loadSales(resetOffset: true);
      case FinanceSection.pix:
        await _controller.loadPixPending();
      case FinanceSection.cancellations:
        await _controller.loadCancellations();
    }
  }
}
