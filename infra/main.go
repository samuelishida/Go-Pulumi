package main

import (
	appsv1 "github.com/pulumi/pulumi-kubernetes/sdk/v4/go/kubernetes/apps/v1"
	corev1 "github.com/pulumi/pulumi-kubernetes/sdk/v4/go/kubernetes/core/v1"
	metav1 "github.com/pulumi/pulumi-kubernetes/sdk/v4/go/kubernetes/meta/v1"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi/config"
)

func main() {
	pulumi.Run(func(ctx *pulumi.Context) error {
		cfg := config.New(ctx, "echo")
		image := cfg.Require("image")
		replicas := cfg.GetInt("replicas")
		nodePort := cfg.GetInt("nodePort")

		labels := pulumi.ToStringMap(map[string]string{"app": "echo"})

		_, err := appsv1.NewDeployment(ctx, "echo", &appsv1.DeploymentArgs{
			Metadata: &metav1.ObjectMetaArgs{Name: pulumi.String("echo")},
			Spec: &appsv1.DeploymentSpecArgs{
				Replicas: pulumi.Int(replicas),
				Selector: &metav1.LabelSelectorArgs{MatchLabels: labels},
				Template: &corev1.PodTemplateSpecArgs{
					Metadata: &metav1.ObjectMetaArgs{Labels: labels},
					Spec: &corev1.PodSpecArgs{
						Containers: corev1.ContainerArray{
							&corev1.ContainerArgs{
								Name:  pulumi.String("echo"),
								Image: pulumi.String(image),
								Ports: corev1.ContainerPortArray{
									&corev1.ContainerPortArgs{ContainerPort: pulumi.Int(8080)},
								},
							},
						},
					},
				},
			},
		})
		if err != nil {
			return err
		}

		_, err = corev1.NewService(ctx, "echo", &corev1.ServiceArgs{
			Metadata: &metav1.ObjectMetaArgs{Name: pulumi.String("echo")},
			Spec: &corev1.ServiceSpecArgs{
				Selector: labels,
				Type:     pulumi.String("NodePort"),
				Ports: corev1.ServicePortArray{
					&corev1.ServicePortArgs{
						Port:       pulumi.Int(8080),
						TargetPort: pulumi.Int(8080),
						NodePort:   pulumi.IntPtr(nodePort),
					},
				},
			},
		})
		if err != nil {
			return err
		}

		ctx.Export("nodePort", pulumi.Int(nodePort))
		return nil
	})
}