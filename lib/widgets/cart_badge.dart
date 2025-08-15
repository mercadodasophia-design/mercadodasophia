import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../theme/app_theme.dart';

class CartBadge extends StatelessWidget {
  final VoidCallback? onTap;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;

  const CartBadge({
    super.key,
    this.onTap,
    this.size = 24,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final itemCount = cartProvider.totalItems;
        
        return GestureDetector(
          onTap: onTap,
          child: Stack(
            children: [
              // Ícone do carrinho
              Icon(
                Icons.shopping_cart,
                size: size,
                color: textColor ?? Colors.white,
              ),
              
              // Badge com contador
              if (itemCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: backgroundColor ?? Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      itemCount > 99 ? '99+' : itemCount.toString(),
                      style: TextStyle(
                        color: textColor ?? Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
